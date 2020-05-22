import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FirebaseLandmarkRecognition {
  FirebaseLandmarkRecognition._();

  static const MethodChannel channel = MethodChannel('landmark_recognition');

  static int nextHandle = 0;

  static final FirebaseLandmarkRecognition instance = FirebaseLandmarkRecognition._();

  LandmarkDetector landmarkDetector() {
    return LandmarkDetector._(nextHandle++);
  }
}

class LandmarkDetector {
  LandmarkDetector._(this._handle);

  final int _handle;
  bool _hasBeenOpened = false;
  bool _isClosed = false;

  Future<List<Landmark>> processImage(FirebaseVisionImage visionImage, Map<String, dynamic> serialize) async {
    assert(!_isClosed);

    _hasBeenOpened = true;
    final List<dynamic> reply =
    await FirebaseLandmarkRecognition.channel.invokeListMethod<dynamic>(
        'StartLandmarkRecognition',
        <String, dynamic> {
          'handle': _handle
        }..addAll(serialize)
    );

    final List<Landmark> landmarks = <Landmark>[];
    for (dynamic data in reply) {
      landmarks.add(Landmark._(data));
    }

    debugPrint('list[landmarks] length: ${landmarks.length}');
    return landmarks;
  }

  Future<void> close() {
    if (!_hasBeenOpened) _isClosed = true;
    if (_isClosed) return Future<void>.value(null);

    _isClosed = true;
    return FirebaseLandmarkRecognition.channel.invokeMethod<void>(
      'CloseLandmarkRecognition',
      <String, dynamic>{'handle': _handle},
    );
  }
}

class Landmark {
  Landmark._(dynamic data)
      : boundingBox = Rect.fromLTWH(
      data['left'],
      data['top'],
      data['width'],
      data['height']
  ),
        landmarkName = data['landmarkName'],
        entityId = data['entityId'],
        confidence = data['confidence'];

  ///
  final Rect boundingBox;

  ///
  final String landmarkName;

  ///
  final String entityId;

  ///
  final double confidence;
}
