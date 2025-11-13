import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '/api/incidentcase_api.dart';
import '/api/file_services_api.dart';
import '/model/incidentcase.dart';
import '../app_theme.dart';
import '/model/IncidentCaseOwnerDetails.dart';
import '/model/driver_log.dart';
import '/model/DriverLogETAUpdate.dart';
import 'file_preview_page.dart';
import '/model/DriverLogStatusUpdate.dart';
import '/model/workshop_panel.dart';
import '../api/driver_api.dart';
import '../api/vehicle_api.dart';
import '../api/driverlog_api.dart';

class OngoingCaseDetailDriver extends StatefulWidget {
  final int caseId;
  final int driverLogID;

  const OngoingCaseDetailDriver({
    super.key,
    required this.caseId,
    required this.driverLogID,
  });

  @override
  State<OngoingCaseDetailDriver> createState() =>
      _OngoingCaseDetailState();
}

class _OngoingCaseDetailState extends State<OngoingCaseDetailDriver> {
  int _currentStep = 0;
  bool _includePoliceStation = false;
  TimeOfDay? _selectedTime;
  bool _isCaseCompleted = false;
  WorkshopPanel? _workshopPanel;
  String? _visibleCard;

  final _etaController = TextEditingController();
  final _policeLocationController = TextEditingController();
  final Map<String, bool> _proofPhotos = {
    'Breakdown Location': false,
    'Police Station': false,
    'Car Workshop': false,
  };

  String? _proofAtBreakdown;
  String? _proofAtPoliceStation;
  String? _proofAtWorkshop;

  IncidentCase? _incidentCase;
  IncidentCaseOwnerDetails? _ownerDetails;
  DriverLog? _driverLog;

  // ---------- DB time stamping helpers ----------
  bool get _hasArrivedBreakdown =>
      _incidentCase?.arrivedAtBreakdownTime != null;
  bool get _hasArrivedPolice =>
      _incidentCase?.arrivedAtPoliceStationTime != null;
  bool get _hasArrivedWorkshop =>
      _incidentCase?.arrivedAtWorkshopTime != null;

  // Incident type helpers
  bool get _isBreakdownCase =>
      (_incidentCase?.type ?? '').toLowerCase() == 'breakdown';

  // whether this case has a workshop assigned
  bool get _hasWorkshopAssigned => _incidentCase?.workshopID != null;

  /// Return non-null DateTime to trigger DB NOW() once via stored procedure,
  /// or null to leave the column unchanged.
  DateTime? _dbNowOrNull(String key) {
    if (key == 'Breakdown Location') {
      return _hasArrivedBreakdown ? null : DateTime.now();
    } else if (key == 'Police Station') {
      return _hasArrivedPolice ? null : DateTime.now();
    } else if (key == 'Car Workshop') {
      return _hasArrivedWorkshop ? null : DateTime.now();
    }
    return null;
  }

  // -------------------- Steps --------------------
  List<Map<String, String>> get _locationSteps {
    final steps = <Map<String, String>>[
      {
        'key': 'Breakdown Location',
        'title': '${_incidentCase?.type ?? 'Breakdown'} Location',
        'description': _incidentCase?.location ?? 'Loading...',
      }
    ];

    if (_includePoliceStation) {
      steps.add({
        'key': 'Police Station',
        'title': 'Police Station',
        'description': _policeLocationController.text.isNotEmpty
            ? _policeLocationController.text
            : '(Enter police station location)',
      });
    }

    // 👉 Only add Car Workshop step if workshop is assigned
    if (_hasWorkshopAssigned) {
      steps.add({
        'key': 'Car Workshop',
        'title': 'Car Workshop',
        'description':
        _workshopPanel?.address ?? '(No workshop address found)',
      });
    }

    return steps;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadIncidentCase();
    _loadOwnerDetails();
  }

  // -------------------- Data loads --------------------

  Future<void> _loadData() async {
    final data = await IncidentCaseAPI.getDriverLogByID(widget.driverLogID);
    if (!mounted) return;
    if (data != null) {
      setState(() {
        _driverLog = data;
        _isCaseCompleted = data.status == 'DRV_COM';
        if (_driverLog?.eta != null) {
          final eta = _driverLog!.eta!;
          _selectedTime = TimeOfDay(hour: eta.hour, minute: eta.minute);
          _etaController.text = _selectedTime!.format(context);
        } else {
          _etaController.text = '';
          _selectedTime = null;
        }
      });
    }
  }

  Future<void> _loadIncidentCase() async {
    final data = await IncidentCaseAPI.getByCaseId(widget.caseId);
    if (data != null) {
      WorkshopPanel? panel;
      if (data.workshopID != null) {
        panel = await IncidentCaseAPI.getByWorkshopId(data.workshopID!);
      }
      if (!mounted) return;

      setState(() {
        _incidentCase = data;
        _workshopPanel = panel;

        final isBreakdown = data.type.toLowerCase() == 'breakdown';

        // If Breakdown -> police station is never included
        _includePoliceStation = !isBreakdown &&
            (data.policeStationLocation?.isNotEmpty == true ||
                data.arrivedAtPoliceStationTime != null ||
                data.proofAtPoliceStationPhoto?.isNotEmpty == true);

        if (isBreakdown) {
          _policeLocationController.clear();
        } else {
          _policeLocationController.text =
              data.policeStationLocation ?? '';
        }

        _proofPhotos['Breakdown Location'] =
            data.proofAtBreakdownPhoto?.isNotEmpty == true;
        _proofPhotos['Police Station'] =
            data.proofAtPoliceStationPhoto?.isNotEmpty == true;
        _proofPhotos['Car Workshop'] =
            data.proofAtWorkshopPhoto?.isNotEmpty == true;

        _currentStep = _getMaxCompletedStep(data);
      });
    }
  }

  void _loadOwnerDetails() async {
    final data = await IncidentCaseAPI.getOwnerDetails(widget.caseId);
    if (!mounted) return;
    if (data != null) {
      setState(() {
        _ownerDetails = data;
      });
    }
  }

  int _getMaxCompletedStep(IncidentCase caseData) {
    int maxStep = 0;

    if (caseData.status == 'DRV_ASSGN' ||
        caseData.status == 'ACP_CASE') {
      maxStep = 0;
    } else if (caseData.status == 'DRV_ARR' &&
        caseData.arrivedAtBreakdownTime != null) {
      maxStep = 0;
    } else if (caseData.status == 'POL_RPT' &&
        caseData.arrivedAtPoliceStationTime != null) {
      maxStep = _includePoliceStation ? 1 : 0;
    } else if (caseData.status == 'TOW') {
      if (_includePoliceStation) {
        if (caseData.arrivedAtPoliceStationTime != null) {
          maxStep = 2;
        } else if (caseData.arrivedAtBreakdownTime != null) {
          maxStep = 1;
        }
      } else {
        if (caseData.arrivedAtBreakdownTime != null) {
          maxStep = 1; // may be clamped if no workshop step
        }
      }
    } else if (caseData.status == 'ARR_WS' &&
        caseData.arrivedAtWorkshopTime != null) {
      maxStep = _includePoliceStation ? 2 : 1;
    } else if (caseData.arrivedAtWorkshopTime != null) {
      maxStep = _includePoliceStation ? 2 : 1;
    } else if (caseData.arrivedAtPoliceStationTime != null) {
      maxStep = _includePoliceStation ? 1 : 0;
    } else if (caseData.arrivedAtBreakdownTime != null) {
      maxStep = 0;
    }

    // 👉 Clamp to actual number of visible steps
    final totalSteps =
        1 + (_includePoliceStation ? 1 : 0) + (caseData.workshopID != null ? 1 : 0);
    if (totalSteps <= 1) {
      return 0;
    }
    if (maxStep > totalSteps - 1) {
      maxStep = totalSteps - 1;
    }
    if (maxStep < 0) maxStep = 0;

    return maxStep;
  }

  String _getFileName(String url) => url.split('/').last;

  @override
  void dispose() {
    _etaController.dispose();
    _policeLocationController.dispose();
    super.dispose();
  }

  String? get _breakdownImage {
    final imgName = _incidentCase?.imgLocation;
    if (imgName == null || imgName.isEmpty) return null;
    return 'https://focsonmyfinger.com/myinsurAPI/api/FileServices/getview/inc_loc/$imgName';
  }

  String get _breakdownLocation =>
      _incidentCase?.location ?? 'No location';
  String get _breakdownDescription =>
      _incidentCase?.descLocation ?? 'No description';

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyAppColors.redDamask,
        title: const Text('Ongoing Case',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [MyAppColors.redDamask, MyAppColors.nobel],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildToggleButton("location", "Location"),
                    _buildToggleButton("vehicle", "Vehicle"),
                    _buildToggleButton("workshop", "Workshop"),
                  ],
                ),
                const SizedBox(height: 10),
                if (_visibleCard == 'location')
                  _buildBreakdownLocationCard(),
                if (_visibleCard == 'vehicle') _buildOwnerCard(),
                if (_visibleCard == 'workshop')
                  _buildWorkshopLocationCard(),
                const SizedBox(height: 20),
                if (_shouldShowEtaToBreakdown())
                  _buildEtaToBreakdownInput(),
                const SizedBox(height: 16),
                _buildStepper(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String key, String label) {
    final isExpanded = _visibleCard == key;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 110,
        child: ElevatedButton.icon(
          onPressed: () =>
              setState(() => _visibleCard = isExpanded ? null : key),
          icon: Icon(
            isExpanded
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            size: 20,
            color: isExpanded ? MyAppColors.redDamask : Colors.black87,
          ),
          label: Text(
            isExpanded ? 'Hide $label' : 'Show $label',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isExpanded ? MyAppColors.redDamask : Colors.black87,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 3,
            minimumSize: const Size(110, 44),
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isExpanded
                    ? MyAppColors.redDamask
                    : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkshopLocationCard() {
    if (_workshopPanel == null) return const SizedBox();

    final address = _workshopPanel!.address ?? 'No address available';
    final logo = _workshopPanel!.companyLogo;

    return Card(
      color: Colors.green.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🛠️ Workshop Details",
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: logo != null && logo.isNotEmpty
                  ? Image.network(
                "https://focsonmyfinger.com/myinsurAPI/api/FileServices/getview/wsp_cl/$logo",
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildImageErrorPlaceholder(),
              )
                  : _buildImageErrorPlaceholder(),
            ),
            const SizedBox(height: 12),
            _buildDetailRow("Company Name",
                _workshopPanel!.companyName ?? 'No Name'),
            _buildPhoneRow("Phone", _workshopPanel!.companyPhoneNo),
            _buildDetailRow("Address",
                _workshopPanel!.address ?? 'Not available'),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final location =
                  Uri.encodeComponent(address);
                  final url = Uri.parse(
                      "https://www.google.com/maps/search/?api=1&query=$location");
                  try {
                    final launched = await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!mounted) return;
                    if (!launched) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text("Unable to open Maps. Please try again.")),
                      );
                    }
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                          Text("Unable to open Maps. Please try again.")),
                    );
                  }
                },
                icon: const Icon(Icons.navigation),
                label: const Text("Open in Maps"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownLocationCard() => Card(
    color: Colors.lightBlue.shade50,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
    elevation: 3,
    margin:
    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "📍 ${_incidentCase?.type ?? 'Breakdown'} Location",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _breakdownImage != null
                ? Image.network(
              _breakdownImage!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _buildImageErrorPlaceholder(),
            )
                : _buildImageErrorPlaceholder(),
          ),
          const SizedBox(height: 12),
          _buildDetailRow("Location", _breakdownLocation),
          _buildDetailRow("Description Location",
              _breakdownDescription),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final location =
                Uri.encodeComponent(_breakdownLocation);
                final url = Uri.parse(
                    "https://www.google.com/maps/search/?api=1&query=$location");
                try {
                  final launched = await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!mounted) return;
                  if (!launched) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              "Unable to open Maps. Please try again.")),
                    );
                  }
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Unable to open Maps. Please try again.")),
                  );
                }
              },
              icon: const Icon(Icons.navigation),
              label: const Text("Open in Maps"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildOwnerCard() {
    if (_ownerDetails == null) return const SizedBox();

    return Card(
      color: Colors.orange.shade100,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🚗 Vehicle Owner Details",
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _ownerDetails!.imgCar.isNotEmpty
                  ? Image.network(
                "https://focsonmyfinger.com/myinsurAPI/api/FileServices/getview/veh_car/${_ownerDetails!.imgCar}",
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildImageErrorPlaceholder(),
              )
                  : _buildImageErrorPlaceholder(),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const Text("👤 Owner Info",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            _buildDetailRow("Name", _ownerDetails!.fullName),
            _buildPhoneRow("Phone", _ownerDetails!.phoneNo),
            const SizedBox(height: 8),
            const Text("🚘 Vehicle Info",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            _buildDetailRow("Car Plate", _ownerDetails!.plateNo),
            _buildDetailRow("Brand", _ownerDetails!.brand),
            _buildDetailRow("Colour", _ownerDetails!.colour),
            _buildDetailRow(
                "Year", _ownerDetails!.manuYear.toString()),
            const SizedBox(height: 8),
            const Text("👥 Alternate Contact",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            _buildDetailRow("Name", _ownerDetails!.alternateName),
            _buildDetailRow("Relationship",
                _ownerDetails!.alternateRelationship),
            _buildPhoneRow("Contact", _ownerDetails!.alternateContact),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ",
              style:
              const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
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
    child: const Text("Image not available",
        style: TextStyle(color: Colors.black45)),
  );

  Widget _buildStepper() => Card(
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
    elevation: 2,
    child: Stepper(
      key: ValueKey(_locationSteps.length),
      currentStep:
      _currentStep.clamp(0, _locationSteps.length - 1),
      controlsBuilder: (_, __) => const SizedBox.shrink(),
      steps: List.generate(_locationSteps.length, (index) {
        final step = _locationSteps[index];
        final key = step['key']!;
        final isComplete = index < _currentStep;
        final isCurrent = index == _currentStep;

        return Step(
          title: Text(step['title']!),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step['description']!),
              const SizedBox(height: 8),

              // Upload Proof Button (triggers DB time once)
              if (isCurrent && !_isCaseCompleted)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final source =
                          await showDialog<ImageSource>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text(
                                  'Select Image Source'),
                              content: const Text(
                                  'How would you like to upload the proof photo?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context,
                                          ImageSource.camera),
                                  child: const Text('Camera'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context,
                                          ImageSource.gallery),
                                  child: const Text('Gallery'),
                                ),
                              ],
                            ),
                          );
                          if (!mounted) return;
                          if (source == null) return;

                          final pickedFile =
                          await picker.pickImage(source: source);
                          if (!mounted) return;
                          if (pickedFile == null) return;

                          final file = File(pickedFile.path);
                          String? uploadedName;
                          String? status;

                          if (key == 'Breakdown Location') {
                            uploadedName =
                            await FileServicesAPI
                                .uploadBreakdownProof(file);
                            if (uploadedName != null) {
                              _proofAtBreakdown = uploadedName;
                              status = 'DRV_ARR';
                            }
                          } else if (key == 'Police Station') {
                            uploadedName =
                            await FileServicesAPI
                                .uploadPoliceStationProof(file);
                            if (uploadedName != null) {
                              _proofAtPoliceStation = uploadedName;
                              status = 'POL_RPT';
                            }
                          } else if (key == 'Car Workshop') {
                            uploadedName =
                            await FileServicesAPI
                                .uploadWorkshopProof(file);
                            if (uploadedName != null) {
                              _proofAtWorkshop = uploadedName;
                              status = 'ARR_WS';
                            }
                          }

                          if (uploadedName != null &&
                              status != null) {
                            final updated =
                            await IncidentCaseAPI
                                .updateOngoingStatus(
                              caseID: widget.caseId,
                              status: status,
                              policeStationLocation:
                              _includePoliceStation
                                  ? _policeLocationController.text
                                  : null,
                              proofAtBreakdownPhoto:
                              _proofAtBreakdown,
                              proofAtPoliceStationPhoto:
                              _proofAtPoliceStation,
                              proofAtWorkshopPhoto:
                              _proofAtWorkshop,
                              arrivedAtBreakdownTime:
                              key == 'Breakdown Location'
                                  ? _dbNowOrNull(key)
                                  : null,
                              arrivedAtPoliceStationTime:
                              key == 'Police Station'
                                  ? _dbNowOrNull(key)
                                  : null,
                              arrivedAtWorkshopTime:
                              key == 'Car Workshop'
                                  ? _dbNowOrNull(key)
                                  : null,
                            );

                            if (!mounted) return;
                            if (updated) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Proof photo uploaded. Status updated to $status.'),
                                ),
                              );
                              await _loadIncidentCase();
                              if (!mounted) return;
                            } else {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Unable to update case status. Please try again.')),
                              );
                            }
                          } else {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Unable to upload proof photo. Please try again.')),
                            );
                          }
                        },
                        icon: Icon(
                          _proofPhotos[key]!
                              ? Icons.check_circle
                              : Icons.upload_file,
                          color: _proofPhotos[key]!
                              ? Colors.green
                              : null,
                        ),
                        label: Text(
                          _proofPhotos[key]!
                              ? "Proof Uploaded"
                              : "Upload Proof",
                          style: TextStyle(
                            color: _proofPhotos[key]!
                                ? Colors.green.shade800
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _proofPhotos[key]!
                              ? Colors.white
                              : MyAppColors.redDamask,
                          side: _proofPhotos[key]!
                              ? const BorderSide(
                              color: Colors.green,
                              width: 1.5)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_proofPhotos[key] == true)
                      IconButton(
                        icon: const Icon(Icons.visibility,
                            color: Colors.blue),
                        tooltip: 'Preview File',
                        onPressed: () {
                          String? photoName;
                          String? dir;
                          if (key == 'Breakdown Location') {
                            photoName =
                                _incidentCase?.proofAtBreakdownPhoto;
                            dir = 'inc_bd';
                          } else if (key == 'Police Station') {
                            photoName = _incidentCase
                                ?.proofAtPoliceStationPhoto;
                            dir = 'inc_ps';
                          } else if (key == 'Car Workshop') {
                            photoName =
                                _incidentCase?.proofAtWorkshopPhoto;
                            dir = 'inc_ws';
                          }

                          if (photoName != null) {
                            final fileName =
                            _getFileName(photoName);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FilePreviewPage(
                                  fileName: fileName,
                                  directory: dir!,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "No proof photo is available to preview.")),
                            );
                          }
                        },
                      ),
                  ],
                ),

              const SizedBox(height: 8),

              // Case Done button (only when NO workshop assigned)
              if (_proofPhotos[key] == true &&
                  key != 'Car Workshop' &&
                  isCurrent &&
                  !_isCaseCompleted &&
                  !_hasWorkshopAssigned)
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("Case Done"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // Need driver & vehicle from driver log
                    if (_driverLog == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text("Driver log information is missing. Please try again later.")),
                      );
                      return;
                    }

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Close Case"),
                        content: const Text(
                          "Are you sure you want to close this case?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text("Yes"),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text("No"),
                          ),
                        ],
                      ),
                    );

                    if (!mounted || confirm != true) return;

                    final driverId = _driverLog!.driverID;
                    final vehicleId = _driverLog!.vehicleID;

                    bool allOk = true;

                    // 1 IncidentCase: status = DONE
                    final caseOk =
                    await IncidentCaseAPI.updateCaseStatus(
                        widget.caseId, 'DONE');
                    if (!caseOk) allOk = false;

                    // 2️ DriverLog: status = CLS-CASE
                    final driverLogStatusOk =
                    await IncidentCaseAPI
                        .updateDriverLogStatus(
                      DriverLogStatusUpdate(
                        driverLogID: widget.driverLogID,
                        status: 'CLS-CASE',
                      ),
                    );
                    if (!driverLogStatusOk) allOk = false;

                    // 3️ DriverLog: complete time using DB time
                    if (driverId != null && vehicleId != null) {
                      final driverLogCompleteOk =
                      await DriverLogAPI.completeDriverLog(
                        driverId: driverId,
                        vehicleId: vehicleId,
                        caseId: widget.caseId,
                      );
                      if (!driverLogCompleteOk) allOk = false;
                    } else {
                      allOk = false;
                    }

                    // 4️⃣ Driver: status = Active
                    if (driverId != null) {
                      final driverOk = await DriverAPI.updateStatus(
                          driverId, 'Active');
                      if (!driverOk) allOk = false;
                    } else {
                      allOk = false;
                    }

                    // 5️⃣ Vehicle: vehicleUse = Available
                    if (vehicleId != null) {
                      final vehicleOk =
                      await VehicleAPI.updateStatus(
                          vehicleId, 'Available');
                      if (!vehicleOk) allOk = false;
                    } else {
                      allOk = false;
                    }

                    if (!mounted) return;

                    if (allOk) {
                      setState(() {
                        _isCaseCompleted = true;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Case closed successfully"),
                        ),
                      );

                      await _loadIncidentCase();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Close Case Failed"),
                        ),
                      );
                    }
                  },
                ),

              // Depart to Next Location (only when workshop is assigned)
              if (_proofPhotos[key] == true &&
                  key != 'Car Workshop' &&
                  isCurrent &&
                  !_isCaseCompleted &&
                  _hasWorkshopAssigned)
                ElevatedButton.icon(
                  icon: const Icon(Icons.local_shipping),
                  label: const Text("Depart to Next Location"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (_currentStep == 0) {
                      // STEP 0: leaving Breakdown
                      if (_isBreakdownCase) {
                        // Breakdown case -> straight to workshop
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title:
                            const Text('Go to Workshop'),
                            content: const Text(
                                'Do you want to go to the workshop now?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('Yes'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('No'),
                              ),
                            ],
                          ),
                        );
                        if (!mounted) return;

                        if (confirm == true) {
                          final updated =
                          await IncidentCaseAPI
                              .updateOngoingStatus(
                            caseID: widget.caseId,
                            status: 'TOW',
                            policeStationLocation: null,
                          );
                          if (!mounted) return;

                          if (updated) {
                            _includePoliceStation = false;
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Next destination set to workshop.")),
                            );
                            await _loadIncidentCase();
                            if (!mounted) return;
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Unable to update next destination. Please try again.")),
                            );
                          }
                        }
                      } else {
                        // Non-Breakdown -> choose Police Station or Workshop
                        await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text(
                                'Select Next Destination'),
                            content: const Text(
                                'Where do you want to go next?'),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  final controller =
                                  TextEditingController();
                                  String? location;

                                  final locationConfirmed =
                                  await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text(
                                          'Police Station Location'),
                                      content: TextField(
                                        controller: controller,
                                        decoration:
                                        const InputDecoration(
                                          labelText:
                                          'Enter police station location',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            if (controller.text
                                                .trim()
                                                .isNotEmpty) {
                                              location = controller
                                                  .text
                                                  .trim();
                                              Navigator.pop(
                                                  context, true);
                                            }
                                          },
                                          child:
                                          const Text('Confirm'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                                  context, false),
                                          child:
                                          const Text('Cancel'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (!mounted) return;

                                  if (locationConfirmed == true &&
                                      location != null) {
                                    final updated =
                                    await IncidentCaseAPI
                                        .updateOngoingStatus(
                                      caseID: widget.caseId,
                                      status: 'TOW',
                                      policeStationLocation:
                                      location,
                                    );
                                    if (!mounted) return;

                                    if (updated) {
                                      _policeLocationController
                                          .text = location!;
                                      _includePoliceStation = true;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Next destination set to police station.")),
                                      );
                                      await _loadIncidentCase();
                                      if (!mounted) return;
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Unable to update next destination. Please try again.")),
                                      );
                                    }
                                  }
                                },
                                child:
                                const Text('Police Station'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final confirm =
                                  await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text(
                                          'Go to Workshop'),
                                      content: const Text(
                                          'Do you want to go to the workshop now?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                                  context, true),
                                          child: const Text('Yes'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(
                                                  context, false),
                                          child:
                                          const Text('No'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (!mounted) return;

                                  if (confirm == true) {
                                    final updated =
                                    await IncidentCaseAPI
                                        .updateOngoingStatus(
                                      caseID: widget.caseId,
                                      status: 'TOW',
                                      policeStationLocation: null,
                                    );
                                    if (!mounted) return;

                                    if (updated) {
                                      _includePoliceStation = false;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Next destination set to workshop.")),
                                      );
                                      await _loadIncidentCase();
                                      if (!mounted) return;
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                "Unable to update next destination. Please try again.")),
                                      );
                                    }
                                  }
                                  Navigator.pop(context);
                                },
                                child: const Text('Workshop'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        );
                      }
                    } else if (_currentStep == 1) {
                      // STEP 1: leaving Police Station to go Workshop
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title:
                          const Text('Go to Workshop'),
                          content: const Text(
                              'Do you want to go to the workshop now?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text("Yes"),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text("No"),
                            ),
                          ],
                        ),
                      );
                      if (!mounted) return;

                      if (confirm == true) {
                        final updated =
                        await IncidentCaseAPI
                            .updateOngoingStatus(
                          caseID: widget.caseId,
                          status: 'TOW',
                          policeStationLocation:
                          _policeLocationController.text,
                        );
                        if (!mounted) return;

                        if (updated) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Next destination set to workshop.")),
                          );
                          await _loadIncidentCase();
                          if (!mounted) return;
                        } else {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Unable to update next destination. Please try again.")),
                          );
                        }
                      }
                    }
                  },
                ),

              // Complete Case Button (after workshop proof)
              if (_proofPhotos[key] == true &&
                  key == 'Car Workshop' &&
                  isCurrent &&
                  !_isCaseCompleted)
                ElevatedButton.icon(
                  icon: const Icon(Icons.done_all),
                  label: const Text("Complete Case"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Complete Case"),
                        content: const Text(
                            "After you complete this case, you will not be able to change the workshop proof photo.\n\nDo you want to mark this case as completed?"),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text("Yes, Complete"),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                        ],
                      ),
                    );
                    if (!mounted) return;

                    if (confirm == true) {
                      final success =
                      await IncidentCaseAPI
                          .updateDriverLogStatus(
                        DriverLogStatusUpdate(
                          driverLogID: widget.driverLogID,
                          status: 'DRV_COM',
                        ),
                      );
                      if (!mounted) return;

                      if (success) {
                        setState(() {
                          _isCaseCompleted = true;
                        });

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Case marked as completed successfully.")),
                        );
                        await _loadIncidentCase();
                        if (!mounted) return;
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Unable to complete the case. Please try again.")),
                        );
                      }
                    }
                  },
                ),

              // Final Confirmation Display
              if (key == 'Car Workshop' && _isCaseCompleted)
                const Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "This case is completed.",
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
            ],
          ),
          isActive: index <= _currentStep,
          state: isComplete
              ? StepState.complete
              : isCurrent
              ? StepState.editing
              : StepState.indexed,
        );
      }),
    ),
  );

  bool _shouldShowEtaToBreakdown() {
    final status = _incidentCase?.status ?? '';
    return (status == 'DRV_ASSGN' || status == 'ACP_CASE');
  }

  Widget _buildEtaToBreakdownInput() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Enter Estimated Time of Arrival (ETA) to Breakdown Location",
        style: TextStyle(color: Colors.white),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () async {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (!mounted) return;
          if (time != null) {
            setState(() {
              _selectedTime = time;
              _etaController.text = time.format(context);
            });
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            controller: _etaController,
            decoration: InputDecoration(
              labelText: 'ETA',
              hintText: 'Select ETA',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.access_time),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
              const SnackBar(
                  content: Text(
                      "Please select an ETA time before submitting.")),
            );
            return;
          }

          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Confirm ETA"),
              content: Text(
                  "Submit ETA as ${_etaController.text}?"),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, true),
                  child: const Text("Yes, Submit"),
                ),
              ],
            ),
          );
          if (!mounted) return;
          if (confirmed != true) return;

          final now = DateTime.now();
          final eta = DateTime(
            now.year,
            now.month,
            now.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          );

          final updated =
          await IncidentCaseAPI.updateETAByDriverLogID(
            DriverLogETAUpdate(
              driverLogID: widget.driverLogID,
              eta: eta,
            ),
          );
          if (!mounted) return;

          if (updated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("ETA submitted successfully.")),
            );
            _loadData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                  Text("Unable to submit ETA. Please try again.")),
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
          Text("$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(hasPhone ? phone : '')),
          if (hasPhone)
            IconButton(
              tooltip: 'Call',
              icon: const Icon(Icons.phone,
                  size: 20, color: Colors.green),
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
