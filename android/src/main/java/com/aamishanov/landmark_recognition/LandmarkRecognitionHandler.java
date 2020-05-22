package com.aamishanov.landmark_recognition;


import android.content.Context;
import android.util.SparseArray;

import com.google.firebase.ml.vision.FirebaseVision;
import com.google.firebase.ml.vision.common.FirebaseVisionImage;
import com.google.firebase.ml.vision.common.FirebaseVisionImageMetadata;

import java.io.IOException;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;


class LandmarkRecognitionHandler implements MethodChannel.MethodCallHandler {

    private final SparseArray<LandmarkDetector> detectors = new SparseArray<>();
    private final Context applicationContext;

    public LandmarkRecognitionHandler(Context applicationContext) {
        this.applicationContext = applicationContext;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "StartLandmarkRecognition":
                handleDetection(call, result);
                break;
            case "CloseLandmarkRecognition":
                closeDetector(call, result);
                break;
            default:
                result.notImplemented();
        }
    }

    private void handleDetection(MethodCall call, MethodChannel.Result result) {
        FirebaseVisionImage image;
        Map<String, Object> imageData = call.arguments();
        try {
            image = dataToVisionImage(imageData);
        } catch (IOException exception) {
            result.error("MLVisionDetectorIOError", exception.getLocalizedMessage(), null);
            return;
        }

        LandmarkDetector detector = getDetector(call);
        if (detector == null) {
            detector = new LandmarkDetector(FirebaseVision.getInstance());
            final Integer handle = call.argument("handle");
            addDetector(handle, detector);
        }

        detector.recognizeLandmarksCloud(image, result);
    }

    private void closeDetector(final MethodCall call, final MethodChannel.Result result) {
        final LandmarkDetector detector = getDetector(call);

        if (detector == null) {
            final Integer handle = call.argument("handle");
            final String message = String.format("Object for handle does not exists: %s", handle);
            throw new IllegalArgumentException(message);
        }

        try {
            detector.close();
            result.success(null);
        } catch (IOException e) {
            final String code = String.format("%sIOError", detector.getClass().getSimpleName());
            result.error(code, e.getLocalizedMessage(), null);
        } finally {
            final Integer handle = call.argument("handle");
            detectors.remove(handle);
        }
    }

    private FirebaseVisionImage dataToVisionImage(Map<String, Object> imageData) throws IOException {
//        String imageType = (String) imageData.get("type");
//        assert imageType != null;
//
//            if (imageType.equals("bytes")) {
            Map<String, Object> metadata = (Map<String, Object>) imageData.get("metadata");
            FirebaseVisionImageMetadata imageMetadata =
                    new FirebaseVisionImageMetadata.Builder()
                        .setWidth(Integer.parseInt((String) metadata.get("width")))
                        .setHeight(Integer.parseInt((String) metadata.get("height")))
                        .setFormat(FirebaseVisionImageMetadata.IMAGE_FORMAT_NV21)
                        .setRotation(FirebaseVisionImageMetadata.ROTATION_90)
                        .build();

            byte[] bytes = (byte[]) imageData.get("bytes");
            assert bytes != null;

            return FirebaseVisionImage.fromByteArray(bytes, imageMetadata);
//        } else {
//            throw new IllegalArgumentException();
//        }
    }

    private int getRotation(int rotation) {
        switch (rotation) {
            case 0:
                return FirebaseVisionImageMetadata.ROTATION_0;
            case 90:
                return FirebaseVisionImageMetadata.ROTATION_90;
            case 180:
                return FirebaseVisionImageMetadata.ROTATION_180;
            case 270:
                return FirebaseVisionImageMetadata.ROTATION_270;
            default:
                throw new IllegalArgumentException();
        }
    }

    private void addDetector(final int handle, final LandmarkDetector detector) {
        if (detectors.get(handle) != null) {
            final String message = String.format("Object for handle already exists: %s", handle);
            throw new IllegalArgumentException(message);
        }

        detectors.put(handle, detector);
    }

    private LandmarkDetector getDetector(final MethodCall call) {
        final Integer handle = call.argument("handle");
        return detectors.get(handle);
    }
}