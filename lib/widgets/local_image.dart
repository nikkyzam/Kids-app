import 'package:flutter/widgets.dart';

import 'local_image_io.dart' if (dart.library.html) 'local_image_web.dart';

/// Returns an [ImageProvider] for a locally stored image path.
///
/// On native targets this is a `FileImage`; on web (where `dart:io` is
/// unavailable) it falls back to a `NetworkImage`, which handles blob URLs
/// produced by the web image picker.
ImageProvider localImageProvider(String path) => buildLocalImageProvider(path);
