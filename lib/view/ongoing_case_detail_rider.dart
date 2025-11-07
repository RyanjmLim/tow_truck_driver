import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '/api/incidentcase_api.dart';
import '/api/file_services_api.dart';
import '/model/incidentcase.dart';
import '/model/IncidentCaseOwnerDetails.dart';
import '../app_theme.dart';
import '/model/DriverLogStatusUpdate.dart';
import '/model/DriverLogETAUpdate.dart';
import '/model/driver_log.dart';
import 'file_preview_page.dart';

class OngoingCaseDetailRider extends StatefulWidget {
  final int caseId;
  final int driverLogID;

  const OngoingCaseDetailRider({
    super.key,
    required this.caseId,
    required this.driverLogID,
  });

  @override
  State<OngoingCaseDetailRider> createState() => _OngoingCaseDetailRiderState();
}

class _OngoingCaseDetailRiderState extends State<OngoingCaseDetailRider> {
  bool _isLoading = true;

  IncidentCase? _incidentCase;
  IncidentCaseOwnerDetails? _ownerDetails;
  DriverLog? _driverLog;
  bool _showOwnerDetails = false;
  bool _showBreakdownDetails = false;
  bool _isCaseCompleted = false;
  String? _proofAtBreakdownPhoto;
  TimeOfDay? _selectedTime;

  final _etaController = TextEditingController();

  String _getFileName(String fullPath) {
    return fullPath.split('/').last;
  }


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final incident = await IncidentCaseAPI.getByCaseId(widget.caseId);
    final owner = await IncidentCaseAPI.getOwnerDetails(widget.caseId);
    final driverLog = await IncidentCaseAPI.getDriverLogByID(widget.driverLogID);

    TimeOfDay? etaTime;
    if (driverLog?.eta != null) {
      final eta = driverLog!.eta!;
      etaTime = TimeOfDay(hour: eta.hour, minute: eta.minute);
      _etaController.text = etaTime.format(context);
    }

    setState(() {
      _proofAtBreakdownPhoto = incident?.proofAtBreakdownPhoto;
      _incidentCase = incident;
      _ownerDetails = owner;
      _driverLog = driverLog;
      _selectedTime = etaTime;
      _isCaseCompleted = driverLog?.status == 'DRV_COM';
      _isLoading = false;
    });
    print('ETA from DB: ${driverLog?.eta}');
  }



  Future<void> _uploadProof() async {
    final picker = ImagePicker();

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Image Source'),
        content: const Text('Choose how you want to upload the proof photo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    final file = File(picked.path);
    final uploaded = await FileServicesAPI.uploadBreakdownProof(file);

    if (uploaded != null) {
      final DateTime now = DateTime.now(); // ✅ define 'now' correctly

      final updated = await IncidentCaseAPI.updateOngoingStatus(
        caseID: widget.caseId,
        status: 'DRV_ARR', // ✅ force status to DRV_ARR
        proofAtBreakdownPhoto: uploaded,
        proofAtPoliceStationPhoto: null,
        proofAtWorkshopPhoto: null,
        arrivedAtBreakdownTime: now, // ✅ set current time
        arrivedAtPoliceStationTime: null,
        arrivedAtWorkshopTime: null,
      );

      if (updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Photo uploaded & saved")),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Upload saved but failed to update record")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Upload failed")),
      );
    }
  }



  Future<void> _completeCase() async {
    if (_proofAtBreakdownPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❗ Please upload a photo before completing.")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Complete Case"),
        content: const Text("Are you sure you want to complete this case?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Complete")),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await IncidentCaseAPI.updateDriverLogStatus(
      DriverLogStatusUpdate(
        driverLogID: widget.driverLogID,
        status: 'DRV_COM',
      ),
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Case completed.")),
      );
      setState(() => _isCaseCompleted = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to update status.")),
      );
    }
  }

  Widget _buildToggleOwnerButton() => ElevatedButton.icon(
    onPressed: () => setState(() => _showOwnerDetails = !_showOwnerDetails),
    icon: Icon(_showOwnerDetails ? Icons.expand_less : Icons.expand_more),
    label: Text(
      _showOwnerDetails ? 'Hide Vehicle' : 'Show Vehicle',
      style: const TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis),
    ),
    style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, foregroundColor: Colors.black),
  );

  Widget _buildToggleBreakdownButton() => ElevatedButton.icon(
    onPressed: () => setState(() => _showBreakdownDetails = !_showBreakdownDetails),
    icon: Icon(_showBreakdownDetails ? Icons.expand_less : Icons.expand_more),
    label: Text(
      _showBreakdownDetails ? 'Hide Breakdown' : 'Show Breakdown',
      style: const TextStyle(fontSize: 13, overflow: TextOverflow.ellipsis),
    ),
    style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, foregroundColor: Colors.black),
  );

  Widget _buildBreakdownLocationCard() {
    if (_incidentCase == null) return const SizedBox();
    final breakdownImage = _incidentCase?.imgLocation != null
        ? "https://focsonmyfinger.com/myinsurAPI/api/FileServices/getview/inc_loc/${_incidentCase!.imgLocation}"
        : null;

    return Card(
      color: Colors.lightBlue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📍 Breakdown Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: breakdownImage != null
                  ? Image.network(
                breakdownImage,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildImageErrorPlaceholder(),
              )
                  : _buildImageErrorPlaceholder(),
            ),
            const SizedBox(height: 12),
            _buildDetailRow("Location", _incidentCase!.location),
            _buildDetailRow("Description Location", _incidentCase!.descLocation ?? 'No description'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final location = Uri.encodeComponent(_incidentCase!.location);
                  final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$location");
                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("❌ Could not open map URL.")),
                    );
                  }
                },
                icon: const Icon(Icons.navigation),
                label: const Text("Open in Maps"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerCard() {
    if (_ownerDetails == null) return const SizedBox();
    return Card(
      color: Colors.orange.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🚗 Vehicle Owner Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _ownerDetails!.imgCar.isNotEmpty
                  ? Image.network(
                "https://focsonmyfinger.com/myinsurAPI/api/FileServices/getview/veh_car/${_ownerDetails!.imgCar}",
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildImageErrorPlaceholder(),
              )
                  : _buildImageErrorPlaceholder(),
            ),
            const SizedBox(height: 12),
            const Divider(),
            _buildDetailRow("Name", _ownerDetails!.fullName),
            _buildPhoneRow("Phone", _ownerDetails!.phoneNo),
            _buildDetailRow("Plate", _ownerDetails!.plateNo),
            _buildDetailRow("Brand", _ownerDetails!.brand),
            _buildDetailRow("Color", _ownerDetails!.colour),
            _buildDetailRow("Year", _ownerDetails!.manuYear.toString()),
            const SizedBox(height: 8),
            _buildDetailRow("Alt Name", _ownerDetails!.alternateName),
            _buildDetailRow("Relationship", _ownerDetails!.alternateRelationship),
            _buildPhoneRow("Alt Contact", _ownerDetails!.alternateContact),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Stepper(
        currentStep: 0,
        controlsBuilder: (_, __) => const SizedBox.shrink(),
        steps: [
          Step(
            title: const Text("Breakdown Location"),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_incidentCase?.location ?? 'No location'),
                const SizedBox(height: 10),

                // Show Upload button ONLY if not completed
                if (!_isCaseCompleted)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _uploadProof,
                          icon: Icon(
                            _proofAtBreakdownPhoto != null ? Icons.check_circle : Icons.upload_file,
                            color: _proofAtBreakdownPhoto != null ? Colors.green : null,
                          ),
                          label: Text(
                            _proofAtBreakdownPhoto != null ? "Proof Uploaded" : "Upload Proof",
                            style: TextStyle(
                              color: _proofAtBreakdownPhoto != null ? Colors.green.shade800 : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _proofAtBreakdownPhoto != null ? Colors.white : MyAppColors.redDamask,
                            side: _proofAtBreakdownPhoto != null
                                ? const BorderSide(color: Colors.green, width: 1.5)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_proofAtBreakdownPhoto != null)
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.blue),
                          tooltip: 'Preview File',
                          onPressed: () {
                            final serverFileName = _getFileName(_proofAtBreakdownPhoto!);
                            const directory = 'inc_bd';
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FilePreviewPage(
                                  fileName: serverFileName,
                                  directory: directory,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),




                // ✅ Show Complete Case button only if photo uploaded AND not completed
                if (_proofAtBreakdownPhoto != null && !_isCaseCompleted)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.done_all),
                    label: const Text("Complete Case"),
                    onPressed: _completeCase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade800,
                      foregroundColor: Colors.white,
                    ),
                  ),

                // ✅ Final completion message if already completed
                if (_isCaseCompleted)
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text("This case is completed.", style: TextStyle(color: Colors.green)),
                    ],
                  ),
              ],
            ),
            isActive: true,
            state: _isCaseCompleted ? StepState.complete : StepState.editing,
          )

        ],
      ),
    );
  }

  Widget _buildImageErrorPlaceholder() => Container(
    height: 160,
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(10),
    ),
    alignment: Alignment.center,
    child: const Text("Image not available", style: TextStyle(color: Colors.black45)),
  );

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyAppColors.redDamask,
        title: const Text("Ongoing Case (Rider)", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [MyAppColors.redDamask, MyAppColors.nobel],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: SizedBox(height: 48, child: _buildToggleBreakdownButton())),
                  const SizedBox(width: 10),
                  Expanded(child: SizedBox(height: 48, child: _buildToggleOwnerButton())),
                ],
              ),
              const SizedBox(height: 10),
              if (_showBreakdownDetails) _buildBreakdownLocationCard(),
              const SizedBox(height: 10),
              if (_showOwnerDetails) _buildOwnerCard(),
              const SizedBox(height: 20),
              if (_shouldShowEtaToBreakdown()) _buildEtaToBreakdownInput(),
              const SizedBox(height: 16),
              _buildStepper(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

  }

  bool _shouldShowEtaToBreakdown() {
    final status = _incidentCase?.status ?? '';
    return (status == 'DRV_ASSGN' || status == 'ACP_CASE');
  }

  Widget _buildEtaToBreakdownInput() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Enter Estimated Time of Arrival (ETA) to Breakdown Location", style: TextStyle(color: Colors.white)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () async {
          final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
          if (time != null) {
            setState(() {
              _selectedTime = time;
              _etaController.text = time.format(context);
            });
          }
        },
        child: AbsorbPointer(
          child:TextFormField(
            controller: _etaController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'ETA', // Always show as placeholder
              labelText: _etaController.text.isNotEmpty ? 'ETA' : null, // Float 'ETA' label only if text exists
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.access_time),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      ElevatedButton.icon(
        icon: const Icon(Icons.send),
        label: const Text("Submit ETA"),
        style: ElevatedButton.styleFrom(
          backgroundColor: MyAppColors.redDamask,
          foregroundColor: Colors.white,
        ),
        onPressed: () async {
          if (_selectedTime == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("❗ Please select time.")),
            );
            return;
          }

          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Confirm ETA Submission"),
              content: Text("Are you sure you want to submit ETA as ${_etaController.text}?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes, Submit")),
              ],
            ),
          );

          if (confirmed != true) return;

          final now = DateTime.now();
          final eta = DateTime(now.year, now.month, now.day, _selectedTime!.hour, _selectedTime!.minute);

          final updated = await IncidentCaseAPI.updateETAByDriverLogID(
            DriverLogETAUpdate(
              driverLogID: widget.driverLogID,
              eta: eta,
            ),
          );

          if (updated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ ETA submitted.")),
            );
            _loadData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("❌ Failed to submit ETA.")),
            );
          }
        },
      ),
    ],
  );


  Widget _buildPhoneRow(String label, String? value) {
    final phone = (value ?? '').trim();
    final hasPhone = phone.isNotEmpty && phone != '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(hasPhone ? phone : '—')),
          if (hasPhone)
            IconButton(
              tooltip: 'Call',
              icon: const Icon(Icons.phone, size: 20, color: Colors.green),
              onPressed: () async {
                final uri = Uri.parse('tel:$phone');
                await launchUrl(uri);
              },
            ),
        ],
      ),
    );
  }

}
