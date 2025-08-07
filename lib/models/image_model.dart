class ImageModel {
  final int id;
  final String filename;
  final String originalName;
  final String url;
  final String mimeType;
  final int size;
  final String formattedSize;
  final int? width;
  final int? height;
  final String? altText;
  final DateTime createdAt;
  final DateTime updatedAt;

  ImageModel({
    required this.id,
    required this.filename,
    required this.originalName,
    required this.url,
    required this.mimeType,
    required this.size,
    required this.formattedSize,
    this.width,
    this.height,
    this.altText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'],
      filename: json['filename'],
      originalName: json['original_name'],
      url: json['url'],
      mimeType: json['mime_type'],
      size: json['size'],
      formattedSize: json['formatted_size'],
      width: json['width'],
      height: json['height'],
      altText: json['alt_text'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'original_name': originalName,
      'url': url,
      'mime_type': mimeType,
      'size': size,
      'formatted_size': formattedSize,
      'width': width,
      'height': height,
      'alt_text': altText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'],
      errors: json['errors'],
    );
  }
}
