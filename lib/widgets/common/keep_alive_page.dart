import 'package:flutter/widgets.dart';

/// A wrapper widget that ensures its [child] is preserved in memory.
///
/// Useful for [PageView] or [TabBarView] children to prevent data loss on scroll.
class KeepAlivePage extends StatefulWidget {
  /// The widget content to keep alive.
  final Widget child;

  /// Optional key for storage persistence.
  final Key? storageKey; // Optional in case it is needed later.

  const KeepAlivePage({super.key, required this.child, this.storageKey});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin<KeepAlivePage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important for KeepAlive.
    // No PageStorage() anymore -> no bucket needed.
    // Optional: attach storageKey to the subtree with KeyedSubtree.
    return widget.storageKey == null
        ? widget.child
        : KeyedSubtree(key: widget.storageKey, child: widget.child);
  }
}
