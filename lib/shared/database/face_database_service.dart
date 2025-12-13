import 'dart:async';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_service.dart';
import 'models/face_models.dart';

/// Database service for face detection and clustering data
class FaceDatabaseService {
  static FaceDatabaseService? _instance;
  static FaceDatabaseService get instance => _instance ??= FaceDatabaseService._();
  
  FaceDatabaseService._();

  Database? _database;
  static const String _tableNameFaces = 'faces';
  static const String _tableNameClusters = 'face_clusters';
  static const String _tableNamePersons = 'persons';
  static const String _tableNamePhotoFaces = 'photo_faces';
  static const String _tableNameProcessingJobs = 'face_processing_jobs';

  // =========================================================================
  // DATABASE INITIALIZATION
  // =========================================================================

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'faces.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onConfigure: _configureDatabase,
    );
  }

  Future<void> _configureDatabase(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createTables(Database db, int version) async {
    // Create faces table
    await db.execute('''
      CREATE TABLE $_tableNameFaces (
        id TEXT PRIMARY KEY,
        photo_id TEXT NOT NULL,
        face_index INTEGER NOT NULL,
        bounding_box TEXT NOT NULL,
        landmarks TEXT NOT NULL,
        confidence REAL NOT NULL,
        embedding BLOB,
        cluster_id TEXT,
        person_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (photo_id) REFERENCES photos (id) ON DELETE CASCADE,
        FOREIGN KEY (cluster_id) REFERENCES $_tableNameClusters (id) ON DELETE SET NULL,
        FOREIGN KEY (person_id) REFERENCES $_tableNamePersons (id) ON DELETE SET NULL
      )
    ''');

    // Create face clusters table
    await db.execute('''
      CREATE TABLE $_tableNameClusters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        face_count INTEGER NOT NULL DEFAULT 0,
        confidence REAL NOT NULL,
        representative_face_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (representative_face_id) REFERENCES $_tableNameFaces (id) ON DELETE SET NULL
      )
    ''');

    // Create persons table
    await db.execute('''
      CREATE TABLE $_tableNamePersons (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        display_name TEXT,
        avatar_photo_id TEXT,
        photo_count INTEGER NOT NULL DEFAULT 0,
        cluster_ids TEXT NOT NULL,
        reference_embeddings TEXT NOT NULL,
        type INTEGER NOT NULL,
        status INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        last_seen TEXT,
        FOREIGN KEY (avatar_photo_id) REFERENCES photos (id) ON DELETE SET NULL
      )
    ''');

    // Create photo-faces relationship table
    await db.execute('''
      CREATE TABLE $_tableNamePhotoFaces (
        id TEXT PRIMARY KEY,
        photo_id TEXT NOT NULL,
        face_id TEXT NOT NULL,
        face_index INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (photo_id) REFERENCES photos (id) ON DELETE CASCADE,
        FOREIGN KEY (face_id) REFERENCES $_tableNameFaces (id) ON DELETE CASCADE,
        UNIQUE(photo_id, face_index)
      )
    ''');

    // Create processing jobs table
    await db.execute('''
      CREATE TABLE $_tableNameProcessingJobs (
        id TEXT PRIMARY KEY,
        photo_id TEXT NOT NULL,
        album_id TEXT,
        status INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT,
        error_message TEXT,
        face_count INTEGER,
        FOREIGN KEY (photo_id) REFERENCES photos (id) ON DELETE CASCADE,
        FOREIGN KEY (album_id) REFERENCES albums (id) ON DELETE SET NULL
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_faces_photo_id ON $_tableNameFaces(photo_id)');
    await db.execute('CREATE INDEX idx_faces_cluster_id ON $_tableNameFaces(cluster_id)');
    await db.execute('CREATE INDEX idx_faces_person_id ON $_tableNameFaces(person_id)');
    await db.execute('CREATE INDEX idx_photo_faces_photo_id ON $_tableNamePhotoFaces(photo_id)');
    await db.execute('CREATE INDEX idx_jobs_status ON $_tableNameProcessingJobs(status)');
  }

  // =========================================================================
  // FACE OPERATIONS
  // =========================================================================

  Future<String> insertFace(FaceEntity face) async {
    final db = await database;
    await db.insert(_tableNameFaces, face.toMap());
    return face.id;
  }

  Future<List<FaceEntity>> insertFaces(List<FaceEntity> faces) async {
    final db = await database;
    final batch = db.batch();
    
    for (final face in faces) {
      batch.insert(_tableNameFaces, face.toMap());
    }
    
    await batch.commit();
    return faces;
  }

  Future<FaceEntity?> getFace(String id) async {
    final db = await database;
    final maps = await db.query(
      _tableNameFaces,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return FaceEntity.fromMap(maps.first);
    }
    return null;
  }

  Future<List<FaceEntity>> getFacesForPhoto(String photoId) async {
    final db = await database;
    final maps = await db.query(
      _tableNameFaces,
      where: 'photo_id = ?',
      whereArgs: [photoId],
      orderBy: 'face_index ASC',
    );
    
    return maps.map((map) => FaceEntity.fromMap(map)).toList();
  }

  Future<List<FaceEntity>> getFacesForCluster(String clusterId) async {
    final db = await database;
    final maps = await db.query(
      _tableNameFaces,
      where: 'cluster_id = ?',
      whereArgs: [clusterId],
      orderBy: 'confidence DESC',
    );
    
    return maps.map((map) => FaceEntity.fromMap(map)).toList();
  }

  Future<List<FaceEntity>> getFacesForPerson(String personId) async {
    final db = await database;
    final maps = await db.query(
      _tableNameFaces,
      where: 'person_id = ?',
      whereArgs: [personId],
      orderBy: 'created_at DESC',
    );
    
    return maps.map((map) => FaceEntity.fromMap(map)).toList();
  }

  Future<List<FaceEntity>> getUnclusteredFaces({int limit = 100}) async {
    final db = await database;
    final maps = await db.query(
      _tableNameFaces,
      where: 'cluster_id IS NULL AND embedding IS NOT NULL',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    
    return maps.map((map) => FaceEntity.fromMap(map)).toList();
  }

  Future<void> updateFace(FaceEntity face) async {
    final db = await database;
    await db.update(
      _tableNameFaces,
      face.toMap(),
      where: 'id = ?',
      whereArgs: [face.id],
    );
  }

  Future<void> assignFaceToCluster(String faceId, String clusterId) async {
    final db = await database;
    await db.update(
      _tableNameFaces,
      {'cluster_id': clusterId},
      where: 'id = ?',
      whereArgs: [faceId],
    );
  }

  Future<void> assignFaceToPerson(String faceId, String personId) async {
    final db = await database;
    await db.update(
      _tableNameFaces,
      {'person_id': personId},
      where: 'id = ?',
      whereArgs: [faceId],
    );
  }

  Future<void> deleteFace(String id) async {
    final db = await database;
    await db.delete(
      _tableNameFaces,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String> insertPhotoFace(PhotoFaceEntity photoFace) async {
    final db = await database;
    await db.insert(_tableNamePhotoFaces, photoFace.toMap());
    return photoFace.id;
  }

  // =========================================================================
  // CLUSTER OPERATIONS
  // =========================================================================

  Future<String> insertCluster(FaceClusterEntity cluster) async {
    final db = await database;
    await db.insert(_tableNameClusters, cluster.toMap());
    return cluster.id;
  }

  Future<FaceClusterEntity?> getCluster(String id) async {
    final db = await database;
    final maps = await db.query(
      _tableNameClusters,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return FaceClusterEntity.fromMap(maps.first);
    }
    return null;
  }

  Future<List<FaceClusterEntity>> getAllClusters() async {
    final db = await database;
    final maps = await db.query(
      _tableNameClusters,
      orderBy: 'face_count DESC',
    );
    
    return maps.map((map) => FaceClusterEntity.fromMap(map)).toList();
  }

  Future<void> updateCluster(FaceClusterEntity cluster) async {
    final db = await database;
    cluster = cluster.copyWith(updatedAt: DateTime.now());
    await db.update(
      _tableNameClusters,
      cluster.toMap(),
      where: 'id = ?',
      whereArgs: [cluster.id],
    );
  }

  Future<void> updateClusterFaceCount(String clusterId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableNameFaces WHERE cluster_id = ?',
      [clusterId],
    );
    
    final count = result.first['count'] as int;
    await db.update(
      _tableNameClusters,
      {
        'face_count': count,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [clusterId],
    );
  }

  Future<void> deleteCluster(String id) async {
    final db = await database;
    await db.delete(
      _tableNameClusters,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================================================================
  // PERSON OPERATIONS
  // =========================================================================

  Future<String> insertPerson(PersonEntity person) async {
    final db = await database;
    await db.insert(_tableNamePersons, person.toMap());
    return person.id;
  }

  Future<PersonEntity?> getPerson(String id) async {
    final db = await database;
    final maps = await db.query(
      _tableNamePersons,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return PersonEntity.fromMap(maps.first);
    }
    return null;
  }

  Future<List<PersonEntity>> getAllPersons() async {
    final db = await database;
    final maps = await db.query(
      _tableNamePersons,
      where: 'status != ?',
      whereArgs: [PersonStatus.hidden.index],
      orderBy: 'photo_count DESC',
    );
    
    return maps.map((map) => PersonEntity.fromMap(map)).toList();
  }

  Future<List<PersonEntity>> getPersonsByType(PersonType type) async {
    final db = await database;
    final maps = await db.query(
      _tableNamePersons,
      where: 'type = ? AND status != ?',
      whereArgs: [type.index, PersonStatus.hidden.index],
      orderBy: 'photo_count DESC',
    );
    
    return maps.map((map) => PersonEntity.fromMap(map)).toList();
  }

  Future<List<PersonEntity>> searchPersons(String query) async {
    final db = await database;
    final maps = await db.query(
      _tableNamePersons,
      where: '(name LIKE ? OR display_name LIKE ?) AND status != ?',
      whereArgs: ['%$query%', '%$query%', PersonStatus.hidden.index],
      orderBy: 'photo_count DESC',
    );
    
    return maps.map((map) => PersonEntity.fromMap(map)).toList();
  }

  Future<void> updatePerson(PersonEntity person) async {
    final db = await database;
    person = person.copyWith(updatedAt: DateTime.now());
    await db.update(
      _tableNamePersons,
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<void> updatePersonPhotoCount(String personId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(DISTINCT photo_id) as count FROM $_tableNameFaces WHERE person_id = ?',
      [personId],
    );
    
    final count = result.first['count'] as int;
    await db.update(
      _tableNamePersons,
      {
        'photo_count': count,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [personId],
    );
  }

  Future<void> deletePerson(String id) async {
    final db = await database;
    await db.delete(
      _tableNamePersons,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================================================================
  // PROCESSING JOB OPERATIONS
  // =========================================================================

  Future<String> insertProcessingJob(FaceProcessingJob job) async {
    final db = await database;
    await db.insert(_tableNameProcessingJobs, job.toMap());
    return job.id;
  }

  Future<FaceProcessingJob?> getProcessingJob(String id) async {
    final db = await database;
    final maps = await db.query(
      _tableNameProcessingJobs,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return FaceProcessingJob.fromMap(maps.first);
    }
    return null;
  }

  Future<List<FaceProcessingJob>> getPendingJobs({int limit = 10}) async {
    final db = await database;
    final maps = await db.query(
      _tableNameProcessingJobs,
      where: 'status = ?',
      whereArgs: [ProcessingStatus.pending.index],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    
    return maps.map((map) => FaceProcessingJob.fromMap(map)).toList();
  }

  Future<void> updateProcessingJob(FaceProcessingJob job) async {
    final db = await database;
    await db.update(
      _tableNameProcessingJobs,
      job.toMap(),
      where: 'id = ?',
      whereArgs: [job.id],
    );
  }

  Future<void> deleteProcessingJob(String id) async {
    final db = await database;
    await db.delete(
      _tableNameProcessingJobs,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> cleanupOldJobs({int daysOld = 7}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    await db.delete(
      _tableNameProcessingJobs,
      where: 'status IN (?, ?) AND created_at < ?',
      whereArgs: [
        ProcessingStatus.completed.index,
        ProcessingStatus.failed.index,
        cutoffDate.toIso8601String(),
      ],
    );
  }

  // =========================================================================
  // UTILITY OPERATIONS
  // =========================================================================

  Future<int> getTotalFaceCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableNameFaces');
    return result.first['count'] as int;
  }

  Future<int> getClusteredFaceCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableNameFaces WHERE cluster_id IS NOT NULL'
    );
    return result.first['count'] as int;
  }

  Future<int> getPersonCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableNamePersons WHERE status != ?',
      [PersonStatus.hidden.index],
    );
    return result.first['count'] as int;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_tableNamePhotoFaces);
    await db.delete(_tableNameFaces);
    await db.delete(_tableNameClusters);
    await db.delete(_tableNamePersons);
    await db.delete(_tableNameProcessingJobs);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
