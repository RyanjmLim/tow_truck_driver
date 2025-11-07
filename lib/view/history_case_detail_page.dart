import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '/api/incidentcase_api.dart';
import '/model/incidentcase.dart';
import '/model/IncidentCaseOwnerDetails.dart';
import '/model/workshop_panel.dart';
import '../app_theme.dart';


class HistoryCaseDetailPage extends StatefulWidget {
  final int caseId;
  const HistoryCaseDetailPage({super.key, required this.caseId});

  @override
  State<HistoryCaseDetailPage> createState() => _HistoryCaseDetailPageState();
}

class _HistoryCaseDetailPageState extends State<HistoryCaseDetailPage> {
  bool _loading = true;
  String? _error;
  IncidentCase? _incidentCase;
  IncidentCaseOwnerDetails? _ownerDetails;
  WorkshopPanel? _workshopPanel;

  /// Build a FileServices URL from a raw filename or path and a directory key
  /// e.g., _fileUrl('inc_loc', inc.imgLocation)
  String? _fileUrl(String dir, String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final name = raw.split('/').last; // handle either plain filename or path
    return 'https://focsonmyfinger.com/myinsurAPI/api/FileServices/getview/$dir/$name';
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final inc = await IncidentCaseAPI.getByCaseId(widget.caseId);
      IncidentCaseOwnerDetails? owner;
      WorkshopPanel? workshop;

      if (inc != null) {
        owner = await IncidentCaseAPI.getOwnerDetails(widget.caseId);
        if (inc.workshopID != null) {
          workshop = await IncidentCaseAPI.getByWorkshopId(inc.workshopID!);
        }
      }

      if (!mounted) return;
      setState(() {
        _incidentCase = inc;
        _ownerDetails = owner;
        _workshopPanel = workshop;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load case details: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyAppColors.redDamask,
        title: const Text('History: Case Details', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [MyAppColors.redDamask, MyAppColors.nobel],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_error!, style: const TextStyle(color: Colors.white)),
          ),
        )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final inc = _incidentCase;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (inc != null) _buildHeaderCard(inc),
        if (inc != null) _buildArrivalTimeline(inc),
        if (inc != null) _buildBreakdownCard(inc),
        if (inc != null) _buildLocationPhotosCard(inc),
        if (inc != null) _buildProofsCard(inc),
        if (_ownerDetails != null) _buildCustomerCard(_ownerDetails!),
        if (_ownerDetails != null) _buildCarCard(_ownerDetails!),
        if (_workshopPanel != null) _buildWorkshopCard(_workshopPanel!),
      ],
    );
  }

  Widget _buildHeaderCard(IncidentCase inc) => _SectionCard(
    title: '📄 Case Overview',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow('Case ID', inc.caseID.toString()),
        _InfoRow('Type', inc.type),
        _InfoRow('Status', inc.status),
        _InfoRow('Location', inc.location),
        _InfoRow('Reported At', DateFormat('yyyy-MM-dd HH:mm').format(inc.timeStamp)),
      ],
    ),
  );

  /// Arrival times section (Breakdown → Police Station → Workshop)
  Widget _buildArrivalTimeline(IncidentCase inc) {
    final items = <Widget>[];
    if (inc.arrivedAtBreakdownTime != null) {
      items.add(_InfoRow('Arrived at Breakdown', DateFormat('yyyy-MM-dd HH:mm').format(inc.arrivedAtBreakdownTime!)));
    }
    if (inc.arrivedAtPoliceStationTime != null) {
      items.add(_InfoRow('Arrived at Police Station', DateFormat('yyyy-MM-dd HH:mm').format(inc.arrivedAtPoliceStationTime!)));
    }
    if (inc.arrivedAtWorkshopTime != null) {
      items.add(_InfoRow('Arrived at Workshop', DateFormat('yyyy-MM-dd HH:mm').format(inc.arrivedAtWorkshopTime!)));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: '🕒 Arrival Timeline',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: items),
    );
  }

  Widget _buildBreakdownCard(IncidentCase inc) {
    final mainImg = _fileUrl('inc_loc', inc.imgLocation);

    return _SectionCard(
      title: '📍 Breakdown Location',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: mainImg != null
                ? Image.network(mainImg, height: 160, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder())
                : _imagePlaceholder(),
          ),
          const SizedBox(height: 8),
          _InfoRow('Location', inc.location),
          _InfoRow('Description', inc.descLocation ?? '—'),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () async {
              final location = Uri.encodeComponent(inc.location);
              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$location');
              await launchUrl(url, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.map),
            label: const Text('Open in Maps'),
          ),
        ],
      ),
    );
  }

  /// Full image set captured at location (front/bottom/side)
  Widget _buildLocationPhotosCard(IncidentCase inc) {
    final photos = <_LabeledImage>[
      _LabeledImage('Front Left', _fileUrl('inc_fl', inc.imgFrontLeft)),
      _LabeledImage('Front Right', _fileUrl('inc_fr', inc.imgFrontRight)),
      _LabeledImage('Bottom Left', _fileUrl('inc_bl', inc.imgBottomLeft)),
      _LabeledImage('Bottom Right', _fileUrl('inc_br', inc.imgBottomRight)),
      _LabeledImage('Side Left', _fileUrl('inc_sl', inc.imgSideLeft)),
      _LabeledImage('Side Right', _fileUrl('inc_sr', inc.imgSideRight)),
    ].where((e) => e.url != null).toList();

    if (photos.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Vehicle Image',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.2,
        ),
        itemCount: photos.length,
        itemBuilder: (_, i) => _PhotoTile(label: photos[i].label, url: photos[i].url!),
      ),
    );
  }

  /// Proof photos (uploaded when arriving at each step)
  Widget _buildProofsCard(IncidentCase inc) {
    final bd = _fileUrl('inc_bd', inc.proofAtBreakdownPhoto);
    final ps = _fileUrl('inc_ps', inc.proofAtPoliceStationPhoto);
    final ws = _fileUrl('inc_ws', inc.proofAtWorkshopPhoto);

    if (bd == null && ps == null && ws == null) return const SizedBox.shrink();

    Widget tile(String label, String url) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => Dialog(
                insetPadding: const EdgeInsets.all(16),
                child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
              ),
            ),
            child: Image.network(
              url,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imagePlaceholder(),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );

    return _SectionCard(
      title: '✅ Proof Photos',
      child: Column(
        children: [
          if (bd != null) tile('Breakdown Location', bd),
          if (bd != null && (ps != null || ws != null)) const SizedBox(height: 12),
          if (ps != null) tile('Police Station', ps),
          if (ps != null && ws != null) const SizedBox(height: 12),
          if (ws != null) tile('Workshop', ws),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(IncidentCaseOwnerDetails owner) => _SectionCard(
    title: '👤 Customer',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow('Name', owner.fullName),
        _PhoneRow('Phone', owner.phoneNo),
        const Divider(),
        const Text('Alternate Contact', style: TextStyle(fontWeight: FontWeight.bold)),
        _InfoRow('Name', owner.alternateName.isNotEmpty ? owner.alternateName : '—'),
        _InfoRow('Relationship', owner.alternateRelationship.isNotEmpty ? owner.alternateRelationship : '—'),
        _PhoneRow('Contact', owner.alternateContact.isNotEmpty ? owner.alternateContact : '—'),
      ],
    ),
  );

  Widget _buildCarCard(IncidentCaseOwnerDetails owner) {
    final img = owner.imgCar.isNotEmpty
        ? 'https://focsonmyfinger.com/myinsurAPI/api/FileServices/getview/veh_car/${owner.imgCar}'
        : null;

    return _SectionCard(
      title: '🚘 Vehicle Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: img != null
                ? Image.network(img, height: 160, fit: BoxFit.cover)
                : _imagePlaceholder(),
          ),
          const SizedBox(height: 8),
          _InfoRow('Plate No', owner.plateNo),
          _InfoRow('Brand', owner.brand),
          _InfoRow('Colour', owner.colour),
          _InfoRow('Manufacture Year', owner.manuYear.toString()),
        ],
      ),
    );
  }

  Widget _buildWorkshopCard(WorkshopPanel panel) {
    final logo = (panel.companyLogo != null && panel.companyLogo!.isNotEmpty)
        ? 'https://focsonmyfinger.com/myinsurAPI/api/FileServices/getview/wsp_cl/${panel.companyLogo}'
        : null;

    return _SectionCard(
      title: '🛠️ Workshop Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: logo != null
                ? Image.network(logo, height: 150, fit: BoxFit.cover)
                : _imagePlaceholder(),
          ),
          const SizedBox(height: 8),
          _InfoRow('Company Name', panel.companyName ?? '—'),
          _PhoneRow('Phone', panel.companyPhoneNo ?? '—'),
          _InfoRow('Address', panel.address ?? '—'),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () async {
              final address = Uri.encodeComponent(panel.address ?? '');
              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$address');
              await launchUrl(url, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.map),
            label: const Text('Open in Maps'),
          )
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    height: 150,
    width: double.infinity,
    color: Colors.grey.shade300,
    alignment: Alignment.center,
    child: const Text('Image not available', style: TextStyle(color: Colors.black54)),
  );
}

class _LabeledImage {
  final String label;
  final String? url;
  _LabeledImage(this.label, this.url);
}

class _PhotoTile extends StatelessWidget {
  final String label;
  final String url;
  const _PhotoTile({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
                ),
              ),
              child: Image.network(
                url,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: const Text('Image not available', style: TextStyle(color: Colors.black54)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  final String label;
  final String value;
  const _PhoneRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final phone = value.trim();
    final isValid = phone.isNotEmpty && phone != '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(isValid ? phone : '—')),
          if (isValid)
            IconButton(
              onPressed: () async { await launchUrl(Uri.parse('tel:$phone')); },
              icon: const Icon(Icons.phone, color: Colors.green, size: 20),
            )
        ],
      ),
    );
  }
}
