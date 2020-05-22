import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:landmark_recognition/landmark_recognition.dart';

class LandmarkRecognitionTest extends StatefulWidget {

  @override
  State createState() => _LandmarkRecognitionTestState();
}


class _LandmarkRecognitionTestState extends State<LandmarkRecognitionTest> {

  var _scanResults;
  CameraController _cameraController;
  Future<void> _initializeCameraController;

  bool _isDetecting = false;
  CameraLensDirection _cameraLensDirection = CameraLensDirection.back;
  List<Landmark> landmarks;
  LandmarkDetector detector;
  ///
  String testText = 'wait...';
  Timer _timer;
  bool _isScanBusy = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<CameraDescription> _getCamera() async {
    return await availableCameras().then(
            (List<CameraDescription> cameras) => cameras.firstWhere(
                (CameraDescription camera) => camera.lensDirection == _cameraLensDirection
        )
    );
  }

  void _initializeCamera() async {
    _cameraController = CameraController(
        await _getCamera(),
        ResolutionPreset.high
    );

    _initializeCameraController = _cameraController.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }


  Future<String> _scanObject(CameraImage image) async {
    final FirebaseVisionImageMetadata metadata = FirebaseVisionImageMetadata(
        rawFormat: image.format.raw,
        size: Size(image.width.toDouble(), image.height.toDouble()),
        planeData: image.planes.map((currentPlane) => FirebaseVisionImagePlaneMetadata(
            bytesPerRow: currentPlane.bytesPerRow,
            height: currentPlane.height,
            width: currentPlane.width
        )).toList(),
        rotation: ImageRotation.rotation90
    );

    Map<String, dynamic> correctMetadata = {
      'width': image.width.toString(),
      'height': image.height.toString()
    };

    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromBytes(
        concatenatePlanes(image.planes),
        metadata
    );

    Map<String, dynamic> _serialize() => <String, dynamic>{
      'bytes': concatenatePlanes(image.planes),
      'metadata': correctMetadata,
    };

    detector = FirebaseLandmarkRecognition.instance.landmarkDetector();
    landmarks = await detector.processImage(visionImage, _serialize());
    print(landmarks);

    return landmarks[0]?.landmarkName;
  }

  Uint8List concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    planes.forEach((Plane plane) => allBytes.putUint8List(plane.bytes));
    return allBytes.done().buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            FutureBuilder<void>(
                future: _initializeCameraController,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Expanded(
                        child: Stack(
                          children: <Widget>[
                            CameraPreview(_cameraController),
                            if (landmarks != null) CustomPaint(
                              painter: CustomRect(landmarks[0].boundingBox),
                            )
                          ],
                        )
                    );
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                }
            ),
            Column(
              children: <Widget>[
                Text(
                  testText,
                  style: TextStyle(
                      fontSize: 28.0
                  ),
                  maxLines: 1,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    FlatButton(
                        color: Colors.green,
                        disabledColor: Colors.green,
                        onPressed: () async {
                          await _cameraController.startImageStream((CameraImage image) async {
                            if (_isScanBusy) return;

                            _isScanBusy = true;
                            _scanObject(image).then((textVision) {
                              setState(() {
                                testText = textVision;
                              });

                              _isScanBusy = false;
                            }).catchError((error) {
                              print(error.toString());
                              _isScanBusy = false;
                            });
                          });
                        },
                        child: Icon(
                          Icons.camera,
                          color: Colors.white,
                        )
                    ),
                    FlatButton(
                        color: Colors.green,
                        disabledColor: Colors.green,
                        onPressed: () async {
                          await _cameraController.stopImageStream();
                          detector?.close();
                          _timer?.cancel();
                        },
                        child: Icon(
                          Icons.camera,
                          color: Colors.white,
                        )
                    ),
                  ],
                )
              ],
            )
          ],
        )
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _timer?.cancel();
    super.dispose();
  }
}

class CustomRect extends CustomPainter {

  final Rect _rect;

  Paint _paintLine = new Paint()
    ..color = Colors.blue;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(_rect, _paintLine);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

  CustomRect(this._rect);
}