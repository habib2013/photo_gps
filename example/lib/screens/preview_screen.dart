import 'package:flutter/material.dart';
import 'package:cdl_photo_gps/cdl_photo_gps.dart';

class PreviewScreen extends StatefulWidget {
  final PhotoCaptureResult result;

  const PreviewScreen({super.key, required this.result});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final CdlPhotoGpsSDK _sdk = CdlPhotoGpsSDK();
  bool _isSaving = false;
  String? _savedPath;

  Future<void> _savePhoto() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Save photo using storage manager
      final bytes = widget.result.photoBytes ?? 
                    (widget.result.photoBase64 != null 
                      ? FormatConverter.base64ToBytes(widget.result.photoBase64!)
                      : null);
      
      if (bytes == null) {
        throw Exception('No photo data available');
      }

      final path = await _sdk.savePhoto(bytes);
      
      setState(() {
        _savedPath = path;
        _isSaving = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo saved to: $path'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.result.locationData;
    final photoBytes = widget.result.photoBytes ?? 
                       (widget.result.photoBase64 != null 
                         ? FormatConverter.base64ToBytes(widget.result.photoBase64!)
                         : null);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Preview'),
        backgroundColor: Colors.black87,
        actions: [
          if (_savedPath == null)
            IconButton(
              onPressed: _isSaving ? null : _savePhoto,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
            ),
        ],
      ),
      body: Column(
        children: [
          // Photo preview
          Expanded(
            child: Center(
              child: photoBytes != null
                  ? Image.memory(
                      photoBytes,
                      fit: BoxFit.contain,
                    )
                  : const Text(
                      'No photo data available',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ),

          // Location info
          Container(
            width: double.infinity,
            color: Colors.black87,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Location Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (widget.result.isMockLocation)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Mock GPS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Location confidence
                _buildInfoRow(
                  Icons.verified,
                  'Location Confidence',
                  '${(widget.result.locationConfidence * 100).toStringAsFixed(0)}%',
                  valueColor: _getConfidenceColor(widget.result.locationConfidence),
                ),
                const SizedBox(height: 8),
                
                _buildInfoRow(
                  Icons.location_on,
                  'Coordinates',
                  location.formattedCoordinates,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.place,
                  'Address',
                  location.address ?? 'Not available',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time,
                  'Timestamp',
                  location.formattedTimestamp,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.gps_fixed,
                  'Accuracy',
                  '${location.accuracy.toStringAsFixed(1)} meters',
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.photo_size_select_actual,
                  'Photo Size',
                  FormatConverter.formatSize(widget.result.photoSize),
                ),
                
                if (widget.result.isMockLocation) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(51), // 0.2 * 255 = 51
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This location was detected as potentially fake. The photo may have been taken with a mock GPS app.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (_savedPath != null) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.folder,
                    'Saved to',
                    _savedPath!,
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Another'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_savedPath == null) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _savePhoto,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
