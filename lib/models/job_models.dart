// lib/models/job_models.dart

import 'package:flutter/widgets.dart';

/// --- Job Model ---
class Job {
  final int jobKey;
  final String allByPNR;
  final String all;
  final String serviceProductName;
  final String driver;
  final String vehicle;
  final String guide;
  final String serviceSupplierName;
  final String comment;
  final Widget paxName;
  final String className;
  final Widget bookingName;
  final int adultQty;
  final int childQty;
  final int childShareQty;
  final int infantQty;
  final String phone;
  final Widget bookingConsultant;
  final String typeName;
  final String serviceTypeName;
  final bool isChange;
  final bool isNew;
  final List<int> keys;
  final int key;
  final String pnr;
  final String pnrDate;
  final String bslId;
  final String pickupDate;
  final String pickup;
  final String dropoffDate;
  final String dropoff;
  final String source;
  final int pax;
  final bool isConfirmed;
  final bool isCancel;
  final dynamic notAvailable;
  final String? photo;
  final String? remark;

  Job({
    required this.jobKey,
    required this.allByPNR,
    required this.all,
    required this.serviceProductName,
    required this.driver,
    required this.vehicle,
    required this.guide,
    required this.serviceSupplierName,
    required this.comment,
    required this.paxName,
    required this.className,
    required this.bookingName,
    required this.adultQty,
    required this.childQty,
    required this.childShareQty,
    required this.infantQty,
    required this.phone,
    required this.bookingConsultant,
    required this.typeName,
    required this.serviceTypeName,
    required this.isChange,
    required this.isNew,
    required this.keys,
    required this.key,
    required this.pnr,
    required this.pnrDate,
    required this.bslId,
    required this.pickupDate,
    required this.pickup,
    required this.dropoffDate,
    required this.dropoff,
    required this.source,
    required this.pax,
    required this.isConfirmed,
    required this.isCancel,
    required this.notAvailable,
    this.photo,
    this.remark,
  });
}

/// --- MergedJob Model ---
class MergedJob extends Job {
  final List<String> pnrList;
  final List<Job> allJobs;
  final Map<String, List<Job>> allByPNRMap;

  MergedJob({
    required this.pnrList,
    required this.allJobs,
    required super.jobKey,
    required super.allByPNR,
    required this.allByPNRMap,
    required super.all,
    required super.serviceProductName,
    required super.driver,
    required super.vehicle,
    required super.guide,
    required super.serviceSupplierName,
    required super.comment,
    required super.paxName,
    required super.className,
    required super.bookingName,
    required super.adultQty,
    required super.childQty,
    required super.childShareQty,
    required super.infantQty,
    required super.phone,
    required super.bookingConsultant,
    required super.typeName,
    required super.serviceTypeName,
    required super.isChange,
    required super.isNew,
    required super.keys,
    required super.key,
    required super.pnr,
    required super.pnrDate,
    required super.bslId,
    required super.pickupDate,
    required super.pickup,
    required super.dropoffDate,
    required super.dropoff,
    required super.source,
    required super.pax,
    required super.isConfirmed,
    required super.isCancel,
    required super.notAvailable,
    super.photo,
    super.remark,
  });
}

/// --- Filter Status Enum ---
enum FilterStatus {
  all,
  confirmed,
  cancelled,
}

/// --- JobKeyObj Model ---
class JobKeyObj {
  final int key;
  final String pnr;
  final String pnrDate;
  final String bookingName;
  final String serviceSupplierCodeTP;

  JobKeyObj({
    required this.key,
    required this.pnr,
    required this.pnrDate,
    required this.bookingName,
    required this.serviceSupplierCodeTP,
  });
}

/// --- JobToAccept Model ---
class JobToAccept {
  final List<JobKeyObj> key;
  final List<bool>? isConfirmed;
  final int indexInGroup;

  JobToAccept({
    required this.key,
    this.isConfirmed,
    required this.indexInGroup,
  });
}

/// --- ImageData Model ---
class ImageData {
  final String imageBase64;

  ImageData({required this.imageBase64});
}

/// --- UploadGroup Model ---
class UploadGroup {
  final int key;
  final String remark;
  final int bookingAssignmentId;
  final String? uploadBy;
  final String? uploadDate;
  final List<ImageData> images;

  UploadGroup({
    required this.key,
    required this.remark,
    required this.bookingAssignmentId,
    this.uploadBy,
    this.uploadDate,
    required this.images,
  });
}

/// --- EmailGuideProps ---
class EmailGuideProps {
  final String guidemail;

  EmailGuideProps({required this.guidemail});
}

/// --- EmailOP Sample Data ---
const List<Map<String, dynamic>> emailOP = [
  {'key': 0, 'Email': ''}, // เพิ่มได้ตามต้องการ
];

/// --- JobsSummaryProps ---
class JobsSummaryProps {
  final List<Job> filteredByDate;

  JobsSummaryProps({required this.filteredByDate});
}

/// --- ConfirmedFilterProps ---
class ConfirmedFilterProps {
  final bool showConfirmedOnly;
  final Function(bool) onChange;

  ConfirmedFilterProps({
    required this.showConfirmedOnly,
    required this.onChange,
  });
}

/// --- PendingFilterProps ---
class PendingFilterProps {
  final bool showPendingOnly;
  final Function(bool) onChange;

  PendingFilterProps({
    required this.showPendingOnly,
    required this.onChange,
  });
}

/// --- FilterProps ---
class FilterProps {
  final FilterStatus value;
  final Function(FilterStatus) onChange;

  FilterProps({required this.value, required this.onChange});
}

/// --- FetchStatusProps ---
class FetchStatusProps {
  final bool loading;
  final String? error;
  final int filteredJobsLength;

  FetchStatusProps({
    required this.loading,
    this.error,
    required this.filteredJobsLength,
  });
}

/// --- JobDetailsProps ---
class JobDetailsProps {
  final Job job;
  final List<Job> jobs;
  final String Function(String) formatDate;

  JobDetailsProps({
    required this.job,
    required this.jobs,
    required this.formatDate,
  });
}

/// --- Props (สำหรับอัปโหลด base64) ---
class UploadProps {
  final void Function(List<String> b64List, String remark) onBase64ListReady;

  UploadProps({required this.onBase64ListReady});
}

/// --- EditFormProps ---
class EditFormProps {
  final String token;
  final int bookingAssignmentId;
  final String uploadedBy;
  final String remark;
  final List<String> previewBase64List;
  final bool loading;
  final String? responseMsg;
  final void Function(String) setRemark;
  final void Function(dynamic e) handleFileChange;
  final void Function() handleUpload;
  final void Function(int indexToDelete) handleRemovePreviewImage;

  EditFormProps({
    required this.token,
    required this.bookingAssignmentId,
    required this.uploadedBy,
    required this.remark,
    required this.previewBase64List,
    required this.loading,
    this.responseMsg,
    required this.setRemark,
    required this.handleFileChange,
    required this.handleUpload,
    required this.handleRemovePreviewImage,
  });
}
