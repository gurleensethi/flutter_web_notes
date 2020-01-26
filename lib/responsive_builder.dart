import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

typedef ResponsiveWidgetBuilder = Widget Function(BuildContext context);
typedef RawResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  DeviceType deviceType,
);

class ResponsiveBuilder extends StatelessWidget {
  final ResponsiveWidgetBuilder mobileBuilder;
  final ResponsiveWidgetBuilder tabletBuilder;
  final ResponsiveWidgetBuilder desktopBuilder;
  final RawResponsiveWidgetBuilder _rawBuilder;

  ResponsiveBuilder({
    Key key,
    this.mobileBuilder,
    this.tabletBuilder,
    this.desktopBuilder,
  })  : _rawBuilder = null,
        super(key: key);

  ResponsiveBuilder._rawBuilder({
    Key key,
    RawResponsiveWidgetBuilder rawBuilder,
  })  : _rawBuilder = rawBuilder,
        mobileBuilder = null,
        tabletBuilder = null,
        desktopBuilder = null;

  factory ResponsiveBuilder.rawBuilder({
    Key key,
    @required RawResponsiveWidgetBuilder builder,
  }) {
    assert(builder != null);
    return ResponsiveBuilder._rawBuilder(
      rawBuilder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    DeviceType deviceType;
    if (mediaQuery.size.width < 600) {
      deviceType = DeviceType.mobile;
    } else if (mediaQuery.size.width < 800) {
      deviceType = DeviceType.tablet;
    } else {
      deviceType = DeviceType.desktop;
    }

    if (this._rawBuilder != null) {
      return _rawBuilder(context, deviceType);
    }

    ResponsiveWidgetBuilder builder;

    switch (deviceType) {
      case DeviceType.mobile:
        builder = this.mobileBuilder;
        break;
      case DeviceType.tablet:
        builder = this.tabletBuilder;
        break;
      case DeviceType.desktop:
        builder = this.desktopBuilder;
        break;
    }

    if (builder == null) {
      builder = mobileBuilder ?? tabletBuilder ?? desktopBuilder;
    }

    return builder(context);
  }
}
