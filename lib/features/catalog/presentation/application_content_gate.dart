import 'package:flutter/material.dart';
import '../data/remote_control_panel_repository.dart';

class ApplicationContentGate extends StatefulWidget {
  const ApplicationContentGate({
    super.key,
    required this.repository,
    required this.child,
  });
  final RemoteControlPanelRepository repository;
  final Widget child;
  @override
  State<ApplicationContentGate> createState() => _ApplicationContentGateState();
}

class _ApplicationContentGateState extends State<ApplicationContentGate>
    with WidgetsBindingObserver {
  late Future<void> loading;
  bool ready = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loading = widget.repository.load();
  }

  void refresh() {
    final next = widget.repository.load();
    setState(() {
      loading = next;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: loading,
    builder: (context, snapshot) {
      if (ready) return widget.child;
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError || widget.repository.provinces.isEmpty) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  snapshot.hasError
                      ? 'تعذر تحميل المحتوى. تحقق من الاتصال ثم حاول مجددًا.'
                      : 'لا توجد وجهات متاحة حاليًا.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: refresh,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        );
      }
      ready = true;
      return widget.child;
    },
  );
}
