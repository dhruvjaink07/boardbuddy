// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloudinary_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UploadedFileMetadataAdapter extends TypeAdapter<UploadedFileMetadata> {
  @override
  final int typeId = 0;

  @override
  UploadedFileMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UploadedFileMetadata(
      filename: fields[0] as String,
      url: fields[1] as String,
      publicId: fields[2] as String,
      size: fields[3] as int,
      resourceType: fields[4] as String,
      uploadedAt: fields[5] as DateTime,
      folder: fields[6] as String,
      fileType: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UploadedFileMetadata obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.filename)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.publicId)
      ..writeByte(3)
      ..write(obj.size)
      ..writeByte(4)
      ..write(obj.resourceType)
      ..writeByte(5)
      ..write(obj.uploadedAt)
      ..writeByte(6)
      ..write(obj.folder)
      ..writeByte(7)
      ..write(obj.fileType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UploadedFileMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
