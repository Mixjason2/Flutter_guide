import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const String testSvgUrl = 'https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/android.svg';
final Widget testSvgWidget = SvgPicture.network(
  'https://upload.wikimedia.org/wikipedia/commons/4/4f/Android_Logo.svg',
  height: 100,
  placeholderBuilder: (_) => CircularProgressIndicator(),
);