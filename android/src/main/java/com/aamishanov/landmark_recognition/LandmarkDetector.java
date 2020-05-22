package com.aamishanov.landmark_recognition;

import com.google.android.gms.tasks.Task;
import com.google.firebase.ml.vision.FirebaseVision;
import com.google.firebase.ml.vision.cloud.FirebaseVisionCloudDetectorOptions;
import com.google.firebase.ml.vision.cloud.landmark.FirebaseVisionCloudLandmark;
import com.google.firebase.ml.vision.cloud.landmark.FirebaseVisionCloudLandmarkDetector;
import com.google.firebase.ml.vision.common.FirebaseVisionImage;
import com.google.firebase.ml.vision.common.FirebaseVisionLatLng;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

public class LandmarkDetector {

    private FirebaseVisionCloudLandmarkDetector detector;

    public LandmarkDetector(FirebaseVision vision) {
        detector = vision.getVisionCloudLandmarkDetector();
    }

    public void recognizeLandmarksCloud(final FirebaseVisionImage image, final MethodChannel.Result result) {
        FirebaseVisionCloudDetectorOptions options =
                new FirebaseVisionCloudDetectorOptions.Builder()
                        .setModelType(FirebaseVisionCloudDetectorOptions.LATEST_MODEL)
                        .setMaxResults(15)
                        .build();

        // [START run_detector_cloud]
        detector.detectInImage(image)
                .addOnSuccessListener(firebaseVisionCloudLandmarks -> {
                    // Task completed successfully
                    // [START_EXCLUDE]
                    // [START get_landmarks_cloud]

                    List<Map<String, Object>> landmarks = new ArrayList<>(firebaseVisionCloudLandmarks.size());
                    for (FirebaseVisionCloudLandmark landmark: firebaseVisionCloudLandmarks) {
                        Map<String, Object> landmarkData = new HashMap<>();

                        landmarkData.put("left", (double) landmark.getBoundingBox().left);
                        landmarkData.put("top", (double) landmark.getBoundingBox().top);
                        landmarkData.put("width", (double) landmark.getBoundingBox().width());
                        landmarkData.put("height", (double) landmark.getBoundingBox().height());

                        landmarkData.put("landmarkName", landmark.getLandmark());
                        landmarkData.put("entityId", landmark.getEntityId());
                        landmarkData.put("confidence", landmark.getConfidence());

                        landmarkData.put("locations", getFirebaseVisionLatLng(landmark));
                        landmarks.add(landmarkData);
                    }
                    // [END get_landmarks_cloud]
                    // [END_EXCLUDE]
                    result.success(landmarks);
                })
                .addOnFailureListener(e -> {
                    result.error("landmarkDetectorError", e.getLocalizedMessage(), null);
                });
        // [END run_detector_cloud]
    }

    private Map<String, double[]> getFirebaseVisionLatLng(FirebaseVisionCloudLandmark landmark) {
        Map<String, double[]> locations = new HashMap<>();
        for (FirebaseVisionLatLng loc: landmark.getLocations()) {
            locations.put(loc.toString(), locationLatLng(loc));
        }

        return locations;
    }

    private double[] locationLatLng(FirebaseVisionLatLng location) {
        return new double[] {location.getLatitude(), location.getLongitude()};
    }

    public void close() throws IOException {
        detector.close();
    }

}
