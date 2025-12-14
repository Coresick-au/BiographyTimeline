import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../shared/models/media_asset.dart';

/// Media player widget for stories that handles different media types
class StoryMediaPlayer extends StatefulWidget {
  final MediaAsset mediaAsset;
  final String? caption;
  final bool autoplay;
  final VoidCallback? onMediaComplete;

  const StoryMediaPlayer({
    super.key,
    required this.mediaAsset,
    this.caption,
    this.autoplay = false,
    this.onMediaComplete,
  });

  @override
  State<StoryMediaPlayer> createState() => _StoryMediaPlayerState();
}

class _StoryMediaPlayerState extends State<StoryMediaPlayer> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    setState(() => _isLoading = true);

    try {
      switch (widget.mediaAsset.type) {
        case 'video':
          await _initializeVideoPlayer();
          break;
        case 'audio':
          await _initializeAudioPlayer();
          break;
        case 'photo':
          // Photos don't need initialization
          break;
        default:
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load media: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeVideoPlayer() async {
    final videoUrl = widget.mediaAsset.cloudUrl ?? widget.mediaAsset.localPath;
    if (videoUrl == null) return;

    _videoController = VideoPlayerController.network(videoUrl);
    await _videoController!.initialize();

    if (widget.autoplay) {
      await _videoController!.play();
    }

    _videoController!.addListener(_videoListener);
    setState(() {});
  }

  Future<void> _initializeAudioPlayer() async {
    final audioUrl = widget.mediaAsset.cloudUrl ?? widget.mediaAsset.localPath;
    if (audioUrl == null) return;

    _audioPlayer = AudioPlayer();
    
    // Set up listeners
    _audioPlayer!.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _audioPlayer!.onPositionChanged.listen((position) {
      setState(() => _position = position);
    });

    _audioPlayer!.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);
    });

    if (widget.autoplay) {
      await _audioPlayer!.play(UrlSource(audioUrl));
    }
  }

  void _videoListener() {
    if (_videoController?.value.isCompleted == true) {
      widget.onMediaComplete?.call();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMediaContent(),
          if (widget.caption != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.caption!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    switch (widget.mediaAsset.type) {
      case 'photo':
        return _buildPhotoPlayer();
      case 'video':
        return _buildVideoPlayer();
      case 'audio':
        return _buildAudioPlayer();
      default:
        return _buildUnsupportedMedia();
    }
  }

  Widget _buildPhotoPlayer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        widget.mediaAsset.cloudUrl ?? widget.mediaAsset.localPath ?? '',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 48),
                  Text('Failed to load image'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return _buildLoadingIndicator();
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_videoController!),
              _buildVideoControls(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoControls() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: _toggleVideoPlayback,
          ),
          Text(
            _formatDuration(_videoController!.value.position),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(width: 16),
          Text(
            _formatDuration(_videoController!.value.duration),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.audiotrack,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio File',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: _toggleAudioPlayback,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: _position.inMilliseconds.toDouble(),
            max: _duration.inMilliseconds.toDouble(),
            onChanged: (value) {
              _seekAudio(Duration(milliseconds: value.round()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedMedia() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_drive_file, size: 48),
            Text('Unsupported media type'),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _toggleVideoPlayback() {
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  void _toggleAudioPlayback() async {
    final audioUrl = widget.mediaAsset.cloudUrl ?? widget.mediaAsset.localPath;
    if (audioUrl == null) return;

    if (_isPlaying) {
      await _audioPlayer!.pause();
    } else {
      await _audioPlayer!.play(UrlSource(audioUrl));
    }
  }

  void _seekAudio(Duration position) async {
    await _audioPlayer!.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

/// Media gallery widget for displaying multiple media items in a story
class StoryMediaGallery extends StatelessWidget {
  final List<MediaAsset> mediaAssets;
  final bool autoplay;

  const StoryMediaGallery({
    super.key,
    required this.mediaAssets,
    this.autoplay = false,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaAssets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: mediaAssets.map((asset) {
        return StoryMediaPlayer(
          mediaAsset: asset,
          caption: asset.caption,
          autoplay: autoplay && mediaAssets.indexOf(asset) == 0,
        );
      }).toList(),
    );
  }
}
