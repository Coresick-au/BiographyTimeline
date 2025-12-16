import 'package:uuid/uuid.dart';
import '../../../shared/models/timeline_event.dart';
import '../../../shared/models/context.dart';
import '../../../shared/models/media_asset.dart';

/// Mock repository for web testing (bypasses SQLite web issues)
class MockTimelineRepository {
  final _uuid = const Uuid();
  
  /// Returns sample timeline events for Brad Leeming (born 1 Feb 1986)
  Future<List<TimelineEvent>> getEvents() async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    return [
      // === BIRTH & EARLY CHILDHOOD (1986-1991) ===
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Birth', 'Origin', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(1986, 2, 1),
        eventType: 'milestone',
        title: 'Born - Brad Leeming',
        description: 'Born on 1st February 1986 in Newcastle, New South Wales, Australia. The beginning of an amazing journey.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Childhood'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(1987, 2, 1),
        eventType: 'milestone',
        title: 'First Birthday',
        description: 'Celebrated first birthday with family. Apparently I smashed cake everywhere!',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Childhood', 'Memory'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(1989, 6, 15),
        eventType: 'photo',
        title: 'Family Beach Day',
        description: 'First time at Nobbys Beach. Dad taught me to build sandcastles.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1001',
            createdAt: DateTime(1989, 6, 15),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Holiday'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(1990, 12, 25),
        eventType: 'photo',
        title: 'Christmas 1990',
        description: 'Got my first bike! Red BMX with training wheels. Best Christmas present ever.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1002',
            createdAt: DateTime(1990, 12, 25),
          )
        ],
        isPrivate: false,
      ),
      
      // === PRIMARY SCHOOL (1991-1997) ===
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Education', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(1991, 2, 4),
        eventType: 'milestone',
        title: 'Started Kindergarten',
        description: 'First day at Wallsend Public School. Mum cried more than I did!',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Sports', 'Achievement'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(1993, 8, 12),
        eventType: 'photo',
        title: 'First Rugby League Game',
        description: 'Joined the Wallsend Ravens junior team. Scored a try in my first game!',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1003',
            createdAt: DateTime(1993, 8, 12),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Memory'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(1994, 4, 10),
        eventType: 'text',
        title: 'Camping at Lake Macquarie',
        description: 'First camping trip with dad and grandpa. Caught my first fish - a bream! Cooked it over the campfire.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Education', 'Achievement'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(1995, 12, 10),
        eventType: 'text',
        title: 'School Captain Nomination',
        description: 'Selected as junior school captain for Year 4. First taste of leadership.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Pet'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(1996, 3, 22),
        eventType: 'photo',
        title: 'Got Max - Our First Dog',
        description: 'Border Collie puppy named Max joined the family. Best mate for the next 14 years.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1004',
            createdAt: DateTime(1996, 3, 22),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Education', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(1997, 12, 15),
        eventType: 'milestone',
        title: 'Graduated Primary School',
        description: 'Finished Year 6 at Wallsend Public. Ready for high school adventures!',
        isPrivate: false,
      ),
      
      // === HIGH SCHOOL (1998-2003) ===
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Education', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(1998, 2, 2),
        eventType: 'milestone',
        title: 'Started High School',
        description: 'First day at Newcastle High School. The school was massive compared to primary!',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Sports', 'Achievement'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(1998, 5, 18),
        eventType: 'photo',
        title: 'Made School Rugby Team',
        description: 'Selected for the Under 13s rugby league school team. Friday arvo games became the highlight of each week.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1005',
            createdAt: DateTime(1998, 5, 18),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(1999, 8, 10),
        eventType: 'text',
        title: 'First Part-Time Job',
        description: 'Got a job at the local servo pumping petrol. \$6.50 an hour felt like being rich!',
        isPrivate: false,
      ),
      
      // === FIRST GIRLFRIEND - SARAH (2000-2004) ===
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Relationship', 'Milestone', 'Love'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2000, 3, 14),
        eventType: 'milestone',
        title: 'Met Sarah',
        description: 'Started dating Sarah from Year 10. She sat next to me in English class. First girlfriend!',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Relationship', 'Memory'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2000, 10, 8),
        eventType: 'photo',
        title: 'Year 10 Social with Sarah',
        description: 'First school dance as a couple. Wore dad\'s old suit that was way too big.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1006',
            createdAt: DateTime(2000, 10, 8),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2001, 2, 1),
        eventType: 'milestone',
        title: 'Turned 15',
        description: 'Birthday party at home. Got a PlayStation 2!',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Education', 'Career'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2001, 5, 15),
        eventType: 'text',
        title: 'Work Experience - Electrician',
        description: 'Two weeks work experience with a local sparky. Loved working with my hands. This might be the career for me!',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2002, 2, 1),
        eventType: 'photo',
        title: 'Turned 16 - Learner\'s Permit',
        description: 'Got my L plates! Dad took me for my first driving lesson in the Commodore. Nearly stalled it 50 times.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1007',
            createdAt: DateTime(2002, 2, 1),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Travel', 'Family'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2002, 7, 5),
        eventType: 'photo_burst',
        title: 'Family Trip to Queensland',
        description: 'Road trip to the Gold Coast. Two weeks of theme parks, beaches, and way too much driving.',
        assets: List.generate(4, (index) => MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '',
          localPath: 'https://picsum.photos/400/300?random=${1008+index}',
          createdAt: DateTime(2002, 7, 5),
        )),
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Sports', 'Achievement'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2002, 9, 14),
        eventType: 'photo',
        title: 'Rugby League Grand Final Victory',
        description: 'Under 17s team won the grand final! Best feeling ever. Scored the winning try in the last 5 minutes.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1012',
            createdAt: DateTime(2002, 9, 14),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Education', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2003, 11, 28),
        eventType: 'milestone',
        title: 'HSC Complete - Graduated High School',
        description: 'Finished the HSC! Not the best marks but enough to get into TAFE. Sarah and I celebrated at Schoolies.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Relationship', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2004, 1, 15),
        eventType: 'text',
        title: 'Sarah and I Split Up',
        description: 'After 4 years, Sarah and I went our separate ways. She was heading to uni in Sydney, I was staying for TAFE. Hard but right.',
        isPrivate: true,
      ),
      
      // === TAFE - ELECTRICAL APPRENTICESHIP (2004-2008) ===
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Education', 'Career', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2004, 2, 16),
        eventType: 'milestone',
        title: 'Started Electrical Apprenticeship',
        description: 'Started Certificate III in Electrotechnology at Hunter TAFE. 4-year apprenticeship with Johnson\'s Electrical.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2004, 2, 20),
        eventType: 'photo',
        title: 'First Car - 1995 VR Commodore',
        description: 'Bought my first car for \$3,500. White VR Commodore with 250,000 kms. She was a beast!',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1013',
            createdAt: DateTime(2004, 2, 20),
          )
        ],
        isPrivate: false,
      ),
      
      // === SECOND GIRLFRIEND - MICHELLE (2004-2014) ===
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Relationship', 'Milestone', 'Love'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2004, 6, 12),
        eventType: 'milestone',
        title: 'Met Michelle',
        description: 'Met Michelle at a mate\'s 18th birthday party. She worked at the Woolies near where I was doing work. Instant connection.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Relationship', 'Memory'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2004, 7, 25),
        eventType: 'photo',
        title: 'First Date with Michelle',
        description: 'Took her to the movies to see Spider-Man 2. Then fish and chips at the beach. Classic!',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1014',
            createdAt: DateTime(2004, 7, 25),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Learning'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2005, 3, 10),
        eventType: 'text',
        title: 'First Solo Electrical Job',
        description: 'Wired my first house solo! Boss checked it all and gave me a thumbs up. Proud moment.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2005, 9, 1),
        eventType: 'milestone',
        title: 'Moved Out of Home',
        description: 'Rented a flat in Mayfield with my mate Davo. Freedom! Mum still did my washing though.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Travel', 'Relationship'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2006, 4, 15),
        eventType: 'photo_burst',
        title: 'First Trip Together - Byron Bay',
        description: 'Week-long trip to Byron with Michelle. Surfing, good food, and zero worries.',
        assets: List.generate(5, (index) => MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '',
          localPath: 'https://picsum.photos/400/300?random=${1015+index}',
          createdAt: DateTime(2006, 4, 15),
        )),
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Hobby'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2006, 11, 20),
        eventType: 'photo',
        title: 'Bought First Boat',
        description: 'Old 14ft tinny with a 25hp Johnson outboard. Lake Macquarie fishing trips every weekend!',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1020',
            createdAt: DateTime(2006, 11, 20),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Relationship', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2007, 6, 12),
        eventType: 'milestone',
        title: 'Moved in Together',
        description: 'Michelle and I got our own place in Lambton. Proper adults now!',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Milestone', 'Achievement'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2008, 2, 28),
        eventType: 'milestone',
        title: 'Qualified Electrician',
        description: 'Completed apprenticeship! Now a fully licensed A-grade electrician. Four years of hard work paid off.',
        isPrivate: false,
      ),
      
      // === TRANSITION TO MINING (2008-2016) ===
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2008, 8, 11),
        eventType: 'milestone',
        title: 'Started Mining Career',
        description: 'Got a job as a sparky at Mount Thorley coal mine. 4 days on, 4 days off roster. Way better pay!',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Vehicle'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2009, 3, 5),
        eventType: 'photo',
        title: 'Upgraded to a Hilux',
        description: 'Finally got the work ute I always wanted. Toyota Hilux SR5 - the tradie\'s dream.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1021',
            createdAt: DateTime(2009, 3, 5),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Sad', 'Memory'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2010, 5, 18),
        eventType: 'text',
        title: 'Max Passed Away',
        description: 'Our family dog Max passed away at 14. Had him since I was 10. Will miss you, old mate.',
        isPrivate: true,
      ),
      
      // === FIRST HOUSE (2010) ===
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Property', 'Milestone', 'Investment'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2010, 9, 22),
        eventType: 'milestone',
        title: 'Bought First House - Cessnock',
        description: 'First home! 3-bedroom house in Cessnock for \$285,000. First home buyer grant helped heaps.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Property', 'Renovation'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2010, 11, 8),
        eventType: 'photo_burst',
        title: 'Renovating the Cessnock House',
        description: 'Spent weekends renovating. New kitchen, bathroom, and painted the whole place. Did most of the work myself.',
        assets: List.generate(4, (index) => MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '',
          localPath: 'https://picsum.photos/400/300?random=${1022+index}',
          createdAt: DateTime(2010, 11, 8),
        )),
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Achievement'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2011, 6, 15),
        eventType: 'milestone',
        title: 'Promoted to Leading Hand',
        description: 'Got promoted to leading hand at the mine. Managing a small crew now.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Travel', 'Adventure'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2011, 9, 5),
        eventType: 'photo_burst',
        title: 'Bali Trip',
        description: 'First OS trip with Michelle! Two weeks in Bali. Surfed, ate amazing food, and relaxed.',
        assets: List.generate(6, (index) => MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '',
          localPath: 'https://picsum.photos/400/300?random=${1026+index}',
          createdAt: DateTime(2011, 9, 5),
        )),
        isPrivate: false,
      ),
      
      // === SECOND HOUSE (2012) ===
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Property', 'Investment', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2012, 4, 12),
        eventType: 'milestone',
        title: 'Bought Second Property - Kurri Kurri',
        description: 'Investment property in Kurri Kurri. 3-bed weatherboard for \$195,000. Rented out straight away.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Hobby'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2012, 8, 20),
        eventType: 'photo',
        title: 'Got into 4WDing',
        description: 'Joined the local 4WD club. Weekend trips to Stockton Beach and Barrington Tops.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1032',
            createdAt: DateTime(2012, 8, 20),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Sad'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2013, 3, 10),
        eventType: 'text',
        title: 'Grandpa Passed Away',
        description: 'Pop passed away at 82. The man who taught me to fish and camp. Miss you, Pop.',
        isPrivate: true,
      ),
      
      // === THIRD HOUSE (2013) ===
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Property', 'Investment', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2013, 7, 28),
        eventType: 'milestone',
        title: 'Bought Third Property - Maitland',
        description: 'Another investment - older cottage in Maitland for \$240,000. Needed work but good bones.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Training'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2013, 11, 5),
        eventType: 'text',
        title: 'High Risk Work Licence',
        description: 'Got my dogging and rigging tickets. Opening up more opportunities on site.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Relationship', 'End'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2014, 2, 14),
        eventType: 'text',
        title: 'Michelle and I Split',
        description: 'After 10 years, Michelle and I decided to go our separate ways. We wanted different things. Still friends.',
        isPrivate: true,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2014, 4, 1),
        eventType: 'text',
        title: 'Single Life Again',
        description: 'Moved into the Cessnock house myself. Time to focus on me for a bit.',
        isPrivate: true,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Hobby'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2014, 10, 12),
        eventType: 'photo',
        title: 'Took Up Golf',
        description: 'Started playing golf with mates from work. Terrible at it but good for networking.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1033',
            createdAt: DateTime(2014, 10, 12),
          )
        ],
        isPrivate: false,
      ),
      
      // === FOURTH HOUSE (2015) ===
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Property', 'Investment', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2015, 3, 18),
        eventType: 'milestone',
        title: 'Bought Fourth Property - Singleton',
        description: 'Mining town investment. 4-bed brick for \$320,000. Rented to FIFO workers.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Achievement'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2015, 8, 22),
        eventType: 'milestone',
        title: 'Promoted to Supervisor',
        description: 'Made electrical supervisor! Managing the whole electrical team now. Big responsibility.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Travel', 'Adventure'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2015, 12, 20),
        eventType: 'photo_burst',
        title: 'Solo Trip to New Zealand',
        description: 'Two weeks exploring NZ South Island. Queenstown, Milford Sound, Mount Cook. Incredible scenery.',
        assets: List.generate(5, (index) => MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '',
          localPath: 'https://picsum.photos/400/300?random=${1034+index}',
          createdAt: DateTime(2015, 12, 20),
        )),
        isPrivate: false,
      ),
      
      // === MOVED TO ORANGE (2016) ===
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Life', 'Milestone', 'Move'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2016, 6, 15),
        eventType: 'milestone',
        title: 'Relocated to Orange',
        description: 'Left the Hunter Valley after 30 years. New job opportunity at Cadia gold mine. Time for a fresh start.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2016, 6, 20),
        eventType: 'milestone',
        title: 'Started at Cadia Gold Mine',
        description: 'First day at Cadia-Ridgeway mine. Biggest underground gold mine in Australia. Exciting times!',
        isPrivate: false,
      ),
      
      // === FIFTH HOUSE - ORANGE (2016) ===
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Property', 'Home', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2016, 9, 8),
        eventType: 'milestone',
        title: 'Bought House in Orange',
        description: 'My new home! 4-bed modern house on a half-acre block. Views of Mount Canobolas. Finally put down roots in Orange.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Pet'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2017, 2, 5),
        eventType: 'photo',
        title: 'Got Rusty - Red Heeler',
        description: 'Adopted a red heeler pup. Named him Rusty because of his colour. Best decision moving to the country.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1039',
            createdAt: DateTime(2017, 2, 5),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Hobby'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2017, 5, 12),
        eventType: 'photo',
        title: 'Started Vegetable Garden',
        description: 'Built raised garden beds and started growing veggies. Love the country life.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1040',
            createdAt: DateTime(2017, 5, 12),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Travel', 'Adventure'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2018, 4, 10),
        eventType: 'photo_burst',
        title: 'Outback Road Trip',
        description: 'Drove to Broken Hill and back. Red dust, amazing sunsets, and the real Aussie outback.',
        assets: List.generate(4, (index) => MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '',
          localPath: 'https://picsum.photos/400/300?random=${1041+index}',
          createdAt: DateTime(2018, 4, 10),
        )),
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Achievement'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2018, 11, 15),
        eventType: 'milestone',
        title: 'Promoted to Maintenance Superintendent',
        description: 'Big promotion at Cadia. Now managing the entire underground electrical maintenance team.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Memory'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2019, 8, 22),
        eventType: 'photo',
        title: 'Orange Wine Festival',
        description: 'Love this annual event. Tasting the local wines with mates. Orange is famous for its cool climate wines.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1045',
            createdAt: DateTime(2019, 8, 22),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Global', 'Life'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2020, 3, 20),
        eventType: 'text',
        title: 'COVID Lockdown Begins',
        description: 'The world changed. Working remotely where possible, but still had to go to site as an essential worker.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Hobby'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2020, 6, 5),
        eventType: 'photo',
        title: 'Built a Home Gym',
        description: 'Converted the garage into a gym during lockdown. Best investment during COVID.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1046',
            createdAt: DateTime(2020, 6, 5),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Hobby'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2021, 3, 12),
        eventType: 'photo',
        title: 'Started Drone Photography',
        description: 'Got a DJI drone. Capturing amazing aerial shots of the Orange countryside.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1047',
            createdAt: DateTime(2021, 3, 12),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Travel', 'Adventure'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2022, 1, 8),
        eventType: 'photo_burst',
        title: 'Tasmania Road Trip',
        description: 'Finally got to Tassie! Two weeks exploring - Cradle Mountain, Port Arthur, Hobart. Incredible place.',
        assets: List.generate(5, (index) => MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '',
          localPath: 'https://picsum.photos/400/300?random=${1048+index}',
          createdAt: DateTime(2022, 1, 8),
        )),
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Vehicle'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2022, 7, 15),
        eventType: 'photo',
        title: 'New 4WD - Land Cruiser 300',
        description: 'The ultimate 4WD! Finally got the 300 Series. Ready for more adventures.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1053',
            createdAt: DateTime(2022, 7, 15),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Achievement'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2023, 4, 1),
        eventType: 'milestone',
        title: '15 Years in Mining',
        description: 'Celebrated 15 years working in the mining industry. From apprentice sparky to superintendent. What a journey!',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Travel', 'Adventure'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2023, 9, 5),
        eventType: 'photo_burst',
        title: 'Kimberley 4WD Adventure',
        description: 'Dream trip to the Kimberley! Gibb River Road, Bungle Bungles, El Questro. Australia\'s last frontier.',
        assets: List.generate(6, (index) => MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '',
          localPath: 'https://picsum.photos/400/300?random=${1054+index}',
          createdAt: DateTime(2023, 9, 5),
        )),
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Hobby'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2024, 2, 1),
        eventType: 'milestone',
        title: 'Turned 38',
        description: 'Another year older! Big birthday BBQ at home with mates. Still feel like I\'m 25 (until I have to get up early).',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Technology', 'Personal'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2024, 6, 15),
        eventType: 'text',
        title: 'Started Building Timeline App',
        description: 'Started working on a personal biography timeline app. Want to document all my life events and memories.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Travel', 'Adventure'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2024, 10, 8),
        eventType: 'photo_burst',
        title: 'Japan Trip',
        description: 'First trip to Japan! Tokyo, Kyoto, Osaka. The food, culture, and organisation blew my mind.',
        assets: List.generate(5, (index) => MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '',
          localPath: 'https://picsum.photos/400/300?random=${1060+index}',
          createdAt: DateTime(2024, 10, 8),
        )),
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Milestone'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2024, 12, 25),
        eventType: 'photo',
        title: 'Christmas 2024',
        description: 'Quiet Christmas at home in Orange. Rusty got extra treats. Life is good.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=1065',
            createdAt: DateTime(2024, 12, 25),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Personal', 'Reflection'],
        ownerId: 'brad-leeming',
        timestamp: DateTime(2025, 2, 1),
        eventType: 'milestone',
        title: 'Turned 39',
        description: 'Last year of my 30s! Looking back at 39 years of adventures. Electrician to mining superintendent, 5 properties, amazing travels. Can\'t wait to see what\'s next.',
        isPrivate: false,
      ),
      
      // === WIFE - EMMA LEEMING (née Thompson) ===
      // Met in 2018, married in 2020
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Birth'],
        ownerId: 'emma-leeming',
        timestamp: DateTime(1989, 7, 15),
        eventType: 'milestone',
        title: 'Emma Born',
        description: 'Emma Thompson born in Sydney. Future wife of Brad!',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Relationship', 'Milestone', 'Love'],
        ownerId: 'brad-leeming',
        participantIds: ['emma-leeming'],
        timestamp: DateTime(2018, 3, 22),
        eventType: 'milestone',
        title: 'Met Emma',
        description: 'Met Emma at a winery event in Orange. She was a nurse at the local hospital. Instant connection!',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Relationship', 'Memory'],
        ownerId: 'brad-leeming',
        participantIds: ['emma-leeming'],
        timestamp: DateTime(2018, 4, 15),
        eventType: 'photo',
        title: 'First Date with Emma',
        description: 'Dinner at a restaurant overlooking the vineyard. She loves red wine as much as I do!',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=2001',
            createdAt: DateTime(2018, 4, 15),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Relationship', 'Milestone'],
        ownerId: 'brad-leeming',
        participantIds: ['emma-leeming'],
        timestamp: DateTime(2018, 12, 25),
        eventType: 'photo',
        title: 'First Christmas Together',
        description: 'Emma spent Christmas at my place. Rusty approved of her immediately.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=2002',
            createdAt: DateTime(2018, 12, 25),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Relationship', 'Travel'],
        ownerId: 'brad-leeming',
        participantIds: ['emma-leeming'],
        timestamp: DateTime(2019, 6, 10),
        eventType: 'photo_burst',
        title: 'Trip to Tasmania with Emma',
        description: 'Exploring Tassie together. Cradle Mountain, Wineglass Bay, and too many cheese platters.',
        assets: List.generate(4, (index) => MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '',
          localPath: 'https://picsum.photos/400/300?random=${2003+index}',
          createdAt: DateTime(2019, 6, 10),
        )),
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Relationship', 'Milestone'],
        ownerId: 'brad-leeming',
        participantIds: ['emma-leeming'],
        timestamp: DateTime(2019, 8, 20),
        eventType: 'milestone',
        title: 'Emma Moved In',
        description: 'Emma moved into the Orange house. Finally feels like a proper home.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Relationship', 'Milestone', 'Love'],
        ownerId: 'brad-leeming',
        participantIds: ['emma-leeming'],
        timestamp: DateTime(2019, 12, 31),
        eventType: 'milestone',
        title: 'Proposed to Emma',
        description: 'Asked Emma to marry me at midnight on New Years Eve. She said YES!',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Wedding', 'Milestone', 'Love', 'Family'],
        ownerId: 'brad-leeming',
        participantIds: ['emma-leeming', 'jake-leeming'],
        timestamp: DateTime(2020, 10, 17),
        eventType: 'photo_burst',
        title: 'Wedding Day - Brad & Emma',
        description: 'Married the love of my life at a vineyard in Orange. Perfect autumn day. Jake was my best man.',
        assets: List.generate(6, (index) => MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '',
          localPath: 'https://picsum.photos/400/300?random=${2010+index}',
          createdAt: DateTime(2020, 10, 17),
        )),
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Travel', 'Honeymoon'],
        ownerId: 'brad-leeming',
        participantIds: ['emma-leeming'],
        timestamp: DateTime(2020, 11, 5),
        eventType: 'photo_burst',
        title: 'Honeymoon - Whitsundays',
        description: 'Sailed around the Whitsundays for our honeymoon. Heart Reef, Whitehaven Beach. Paradise!',
        assets: List.generate(5, (index) => MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '',
          localPath: 'https://picsum.photos/400/300?random=${2020+index}',
          createdAt: DateTime(2020, 11, 5),
        )),
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Holiday'],
        ownerId: 'brad-leeming',
        participantIds: ['emma-leeming'],
        timestamp: DateTime(2021, 12, 25),
        eventType: 'photo',
        title: 'Christmas 2021 - Our First as Married',
        description: 'First Christmas as Mr and Mrs Leeming. Emma made an incredible Christmas lunch.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=2025',
            createdAt: DateTime(2021, 12, 25),
          )
        ],
        isPrivate: false,
      ),
      
      // === BROTHER - JAKE LEEMING ===
      // Younger brother, born 1990
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Birth'],
        ownerId: 'jake-leeming',
        timestamp: DateTime(1990, 5, 8),
        eventType: 'milestone',
        title: 'Jake Born',
        description: 'Little brother Jake born. Now I have someone to share toys with (and blame)!',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Memory'],
        ownerId: 'brad-leeming',
        participantIds: ['jake-leeming'],
        timestamp: DateTime(1995, 12, 25),
        eventType: 'photo',
        title: 'Christmas 1995 - Brothers',
        description: 'Classic 90s Christmas with Jake. We both got Nerf guns and had an epic battle.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=3001',
            createdAt: DateTime(1995, 12, 25),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Sports'],
        ownerId: 'brad-leeming',
        participantIds: ['jake-leeming'],
        timestamp: DateTime(2002, 8, 15),
        eventType: 'photo',
        title: 'Rugby Grand Final - Brothers Playing Together',
        description: 'Jake joined my rugby team this year. We won the grand final together!',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=3002',
            createdAt: DateTime(2002, 8, 15),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Travel'],
        ownerId: 'brad-leeming',
        participantIds: ['jake-leeming'],
        timestamp: DateTime(2010, 7, 20),
        eventType: 'photo_burst',
        title: 'Brothers Trip to Thailand',
        description: 'Boys trip to Thailand with Jake. Bangkok, Phuket, Full Moon Party. Wild times!',
        assets: List.generate(4, (index) => MediaAsset.photo(
          id: _uuid.v4(),
          eventId: '',
          localPath: 'https://picsum.photos/400/300?random=${3010+index}',
          createdAt: DateTime(2010, 7, 20),
        )),
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Milestone'],
        ownerId: 'jake-leeming',
        participantIds: ['brad-leeming'],
        timestamp: DateTime(2015, 4, 18),
        eventType: 'milestone',
        title: 'Jake Got Married',
        description: 'Jake married his girlfriend Sarah. I was his best man. Proud moment.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'BBQ'],
        ownerId: 'brad-leeming',
        participantIds: ['jake-leeming', 'emma-leeming'],
        timestamp: DateTime(2022, 1, 26),
        eventType: 'photo',
        title: 'Australia Day BBQ - Family',
        description: 'Big Australia Day BBQ at my place. Jake and his family came up from Newcastle. Great to see him.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=3020',
            createdAt: DateTime(2022, 1, 26),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Holiday'],
        ownerId: 'brad-leeming',
        participantIds: ['emma-leeming', 'jake-leeming'],
        timestamp: DateTime(2023, 12, 25),
        eventType: 'photo',
        title: 'Christmas 2023 - Full Family',
        description: 'Christmas at mums with Emma and Jake\'s family. Three generations together.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=3025',
            createdAt: DateTime(2023, 12, 25),
          )
        ],
        isPrivate: false,
      ),
      
      // Emma's solo events
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Milestone'],
        ownerId: 'emma-leeming',
        timestamp: DateTime(2012, 6, 15),
        eventType: 'milestone',
        title: 'Emma - Graduated Nursing',
        description: 'Emma graduated from nursing school at UTS Sydney.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Milestone'],
        ownerId: 'emma-leeming',
        timestamp: DateTime(2017, 3, 1),
        eventType: 'milestone',
        title: 'Emma - Moved to Orange',
        description: 'Emma took a position at Orange Base Hospital. Best decision she ever made!',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Achievement'],
        ownerId: 'emma-leeming',
        timestamp: DateTime(2022, 8, 10),
        eventType: 'milestone',
        title: 'Emma - Promoted to Nurse Unit Manager',
        description: 'Emma promoted to Nurse Unit Manager at the hospital. So proud of her!',
        isPrivate: false,
      ),
      
      // Jake's career events
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Milestone'],
        ownerId: 'jake-leeming',
        timestamp: DateTime(2012, 2, 15),
        eventType: 'milestone',
        title: 'Jake - Started Plumbing Apprenticeship',
        description: 'Jake followed the trades path too. Started his plumbing apprenticeship.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Achievement'],
        ownerId: 'jake-leeming',
        timestamp: DateTime(2020, 6, 1),
        eventType: 'milestone',
        title: 'Jake - Started Own Plumbing Business',
        description: 'Jake started his own plumbing business in Newcastle. Leeming Plumbing Services.',
        isPrivate: false,
      ),
      
      // === MUM - KAREN LEEMING ===
      // Brad's mother
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Birth'],
        ownerId: 'karen-leeming',
        timestamp: DateTime(1960, 3, 22),
        eventType: 'milestone',
        title: 'Karen Born',
        description: 'Karen born in Newcastle. Future mum of Brad and Jake.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Milestone'],
        ownerId: 'karen-leeming',
        participantIds: ['peter-leeming'],
        timestamp: DateTime(1982, 11, 15),
        eventType: 'milestone',
        title: 'Mum & Dad Got Married',
        description: 'Karen and Peter tied the knot at St Johns Church, Newcastle.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Birth'],
        ownerId: 'karen-leeming',
        participantIds: ['peter-leeming', 'brad-leeming'],
        timestamp: DateTime(1986, 2, 1),
        eventType: 'milestone',
        title: 'Brad Was Born',
        description: 'Karen and Peter welcomed their first son, Brad.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Birth'],
        ownerId: 'karen-leeming',
        participantIds: ['peter-leeming', 'jake-leeming'],
        timestamp: DateTime(1990, 5, 8),
        eventType: 'milestone',
        title: 'Jake Was Born',
        description: 'Karen and Peter welcomed their second son, Jake.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Holiday'],
        ownerId: 'karen-leeming',
        participantIds: ['peter-leeming', 'brad-leeming', 'jake-leeming'],
        timestamp: DateTime(1998, 12, 25),
        eventType: 'photo',
        title: 'Family Christmas 1998',
        description: 'Whole family Christmas at the Leeming house. Boys got Playstations!',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=4001',
            createdAt: DateTime(1998, 12, 25),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Holiday'],
        ownerId: 'karen-leeming',
        participantIds: ['peter-leeming', 'brad-leeming', 'jake-leeming', 'emma-leeming'],
        timestamp: DateTime(2019, 12, 25),
        eventType: 'photo',
        title: 'Family Christmas 2019',
        description: 'First Christmas with Emma as part of the family. Mum was so happy.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=4002',
            createdAt: DateTime(2019, 12, 25),
          )
        ],
        isPrivate: false,
      ),
      
      // === DAD - PETER LEEMING ===
      // Brad's father
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Birth'],
        ownerId: 'peter-leeming',
        timestamp: DateTime(1958, 8, 10),
        eventType: 'milestone',
        title: 'Peter Born',
        description: 'Peter born in Newcastle. Future dad of Brad and Jake.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Milestone'],
        ownerId: 'peter-leeming',
        timestamp: DateTime(1976, 6, 15),
        eventType: 'milestone',
        title: 'Dad Started Mining',
        description: 'Peter started working at the local coal mine. Career that would span 40 years.',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Hobby'],
        ownerId: 'peter-leeming',
        participantIds: ['brad-leeming'],
        timestamp: DateTime(1992, 4, 5),
        eventType: 'photo',
        title: 'Dad Taught Brad to Fish',
        description: 'First fishing trip with Dad at Lake Macquarie. Caught my first fish!',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=4003',
            createdAt: DateTime(1992, 4, 5),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Hobby'],
        ownerId: 'peter-leeming',
        participantIds: ['brad-leeming', 'jake-leeming'],
        timestamp: DateTime(2000, 7, 15),
        eventType: 'photo',
        title: 'Camping Trip - Three Generations',
        description: 'Dad took both boys camping to the same spot grandpa took him.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=4004',
            createdAt: DateTime(2000, 7, 15),
          )
        ],
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Career', 'Milestone'],
        ownerId: 'peter-leeming',
        participantIds: ['karen-leeming', 'brad-leeming', 'jake-leeming'],
        timestamp: DateTime(2016, 8, 12),
        eventType: 'milestone',
        title: 'Dad Retired',
        description: 'Peter retired after 40 years in mining. Big family celebration!',
        isPrivate: false,
      ),
      
      TimelineEvent.create(
        id: _uuid.v4(),
        tags: ['Family', 'Wedding'],
        ownerId: 'peter-leeming',
        participantIds: ['karen-leeming', 'brad-leeming', 'emma-leeming', 'jake-leeming'],
        timestamp: DateTime(2020, 10, 17),
        eventType: 'photo',
        title: 'Dad at Brad\'s Wedding',
        description: 'Proudest moment - watching my son marry the love of his life.',
        assets: [
          MediaAsset.photo(
            id: _uuid.v4(),
            eventId: '',
            localPath: 'https://picsum.photos/400/300?random=4005',
            createdAt: DateTime(2020, 10, 17),
          )
        ],
        isPrivate: false,
      ),
    ];
  }
  
  /// Returns sample contexts for Brad Leeming
  Future<List<Context>> getContexts() async {
    await Future.delayed(const Duration(milliseconds: 50));
    
    return [
      Context(
        id: _uuid.v4(),
        ownerId: 'brad-leeming',
        type: ContextType.person,
        name: 'Brad Leeming',
        description: 'My personal life timeline - from Newcastle sparky to Orange mining superintendent',
        moduleConfiguration: {},
        themeId: 'personal_theme',
        createdAt: DateTime(1986, 2, 1),
        updatedAt: DateTime.now(),
      ),
    ];
  }
  
  // Stub methods for CRUD operations (not needed for read-only testing)
  Future<void> addEvent(TimelineEvent event) async {}
  Future<void> updateEvent(TimelineEvent event) async {}
  Future<void> removeEvent(String eventId) async {}
  Future<void> addContext(Context context) async {}
  Future<void> updateContext(Context context) async {}
  Future<void> removeContext(String contextId) async {}
}
