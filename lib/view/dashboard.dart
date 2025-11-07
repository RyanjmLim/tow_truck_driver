import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/model/sys_user.dart';
import '/model/incidentcase.dart';
import '/api/incidentcase_api.dart';
import 'update_details.dart';
import 'ongoing_case_detail_driver.dart';
import 'ongoing_case_detail_rider.dart';
import '../app_theme.dart';
import '/model/DriverCaseInfo.dart';
import 'dart:async';
import '../main.dart';
import 'history_case_detail_page.dart';


class DashboardPage extends StatefulWidget {
  final SysUser sysUser;

  const DashboardPage({
    super.key,
    required this.sysUser,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with RouteAware {
  IncidentCase? _incidentCase;
  DriverCaseInfo? _caseInfo;
  bool isLoading = true;
  Timer? _refreshTimer;

  List<DriverCaseInfo> _caseHistory = [];
  bool _showAllHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    });
    _startAutoRefresh();

  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didPush() {
    _startAutoRefresh();
  }

  @override
  void didPopNext() {
    _startAutoRefresh();
  }

  @override
  void didPushNext() {
    _stopAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadIncidentCase();
      _loadDriverHistory();
    });
    _loadIncidentCase();
    _loadDriverHistory();
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  Future<void> _loadIncidentCase() async {
    try {
      final caseInfo = await IncidentCaseAPI.getCurrentCaseInfo(widget.sysUser.id);
      if (caseInfo != null) {
        final result = await IncidentCaseAPI.getByCaseId(caseInfo.caseID);
        if (mounted) {
          setState(() {
            _caseInfo = caseInfo;
            _incidentCase = result;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _incidentCase = null;
            _caseInfo = null;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Failed to load incident case: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadDriverHistory() async {
    try {
      final history = await IncidentCaseAPI.getHistoryByUserID(widget.sysUser.id);
      if (mounted) {
        setState(() {
          _caseHistory = history;
        });
      }
    } catch (e) {
      print('❌ Failed to load driver history: $e');
    }
  }

  Widget _buildIncidentCaseCard() {
    if (_incidentCase == null || _caseInfo == null) {
      return const Center(
        child: Text(
          '❗ No Incident Case Found',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    final incident = _incidentCase!;
    final caseInfo = _caseInfo!;
    final type = incident.type.toLowerCase();
    final remark = caseInfo.remark.toLowerCase();

    Widget mainIcon;
    if (type == 'accident' || type == 'breakdown') {
      mainIcon = const Text('🚨', style: TextStyle(fontSize: 24));
    } else if (type == 'battery bank') {
      mainIcon = const Icon(Icons.battery_charging_full, color: Colors.redAccent, size: 24);
    } else {
      mainIcon = const Icon(Icons.warning, color: Colors.orange, size: 24);
    }

    Widget? cornerIcon;
    if (remark == 'motorbike') {
      cornerIcon = const Icon(Icons.motorcycle, size: 30, color: Colors.black87);
    } else if (remark == 'tow truck') {
      cornerIcon = const Icon(Icons.local_shipping, size: 30, color: Colors.black87);
    } else if (remark == 'car') {
      cornerIcon = const Icon(Icons.directions_car, size: 30, color: Colors.black87);
    }

    return InkWell(
      onTap: () async {
        if ((type == 'breakdown' || type == 'accident') && remark == 'tow truck') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OngoingCaseDetailDriver(
                caseId: caseInfo.caseID,
                driverLogID: caseInfo.driverLogID,
              ),
            ),
          );
        } else if (type == 'battery bank' || remark == 'motorbike' || remark == 'car') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OngoingCaseDetailRider(
                caseId: caseInfo.caseID,
                driverLogID: caseInfo.driverLogID,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❗ Unsupported case type or remark')),
          );
        }

        _loadIncidentCase();
      },
      child: Stack(
        children: [
          Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      mainIcon,
                      const SizedBox(width: 6),
                      const Text(
                        'Incident Case Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(height: 10, thickness: 1),
                  _buildInfoRow("Case ID", incident.caseID.toString()),
                  _buildInfoRow("Type", incident.type),
                  _buildInfoRow("Location", incident.location),
                  _buildInfoRow("Time", DateFormat('yyyy-MM-dd HH:mm').format(incident.timeStamp)),
                  _buildInfoRow("Service Type", caseInfo.serviceType ?? "—"),
                ],
              ),
            ),

          ),
          if (cornerIcon != null)
            Positioned(
              top: 8,
              left: 12,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                child: cornerIcon,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_caseHistory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No completed cases found.', style: TextStyle(color: Colors.white)),
      );
    }

    final displayed = _showAllHistory ? _caseHistory : _caseHistory.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Text(
            '📜 Task History',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...displayed.map((entry) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text('Case ID: ${entry.caseID}'),
              subtitle: Text('Type: ${entry.type} • Status: ${entry.status}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  backgroundColor: Colors.white,
                  builder: (_) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📄 Case History Detail',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _infoText('Case ID', entry.caseID.toString()),
                        _infoText('Driver Log ID', entry.driverLogID.toString()),
                        _infoText('Driver ID', entry.driverID.toString()),
                        _infoText('Status', entry.status),
                        _infoText('Type', entry.type),
                        _infoText('Service Type', entry.serviceType ?? "—"),
                        _infoText('Remark', entry.remark),
                        _infoText('Location', entry.location),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },

            ),
          ),
        )),
        if (_caseHistory.length > 3)
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showAllHistory = !_showAllHistory;
                });
              },
              child: Text(_showAllHistory ? 'Show Less ▲' : 'Show More ▼'),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
        automaticallyImplyLeading: false,
        backgroundColor: MyAppColors.redDamask,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            Image.asset('assets/images/logo.png', height: 75),
            const SizedBox(width: 8),
            const Text(
              'BantuPandu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
            ),
            const Spacer(),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: const Icon(Icons.account_circle, size: 40, color: Colors.white),
              tooltip: 'Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UpdateDetailsPage(userId: widget.sysUser.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [MyAppColors.redDamask, MyAppColors.nobel],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: _buildIncidentCaseCard(),
              ),
            ),

            const Divider(color: Colors.white, height: 1),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '📜 Task History',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Scrollable History Section
            Expanded(
              child: _caseHistory.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No completed cases found.',
                  style: TextStyle(color: Colors.white),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _showAllHistory ? _caseHistory.length : (_caseHistory.length > 3 ? 3 : _caseHistory.length),
                itemBuilder: (context, index) {
                  final entry = _caseHistory[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text('Case ID: ${entry.caseID}'),
                        subtitle: Text('Time: ${DateFormat('yyyy-MM-dd HH:mm').format(entry.timeStamp)}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HistoryCaseDetailPage(caseId: entry.caseID),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // Show More / Show Less
            if (_caseHistory.length > 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllHistory = !_showAllHistory;
                    });
                  },
                  child: Text(
                    _showAllHistory ? 'Show Less ▲' : 'Show More ▼',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),

    );
  }
}