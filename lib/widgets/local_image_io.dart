import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider buildLocalImageProvider(String path) => FileImage(File(path));
