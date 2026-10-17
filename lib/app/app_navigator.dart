import 'package:flutter/widgets.dart';

/// Root navigator key so app-level UI (the ban/appeal dialog) can be shown
/// above whatever screen is currently on top, including from outside the
/// widget tree's normal route flow.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
