package com.fpt.alertservice;

import java.util.ArrayList;
import java.util.List;

/**
 * AlertService - the core business logic.
 * Decide which predictions are high-confidence enough to alert on.
 */
public class AlertService {

    // The threshold: only predictions above this probability trigger an alert.
    private final double threshold;

    // Constructor - lets us set the threshold (defaults handled in Main)
    public AlertService(double threshold) {
        this.threshold = threshold;
    }

    /**
     * Takes all predictions and returns only the ones above the threshold.
     * These are the "high-value events" the spec asks us to capture.
     */
    public List<Prediction> findAlerts(List<Prediction> predictions) {
        List<Prediction> alerts = new ArrayList<>();
        for (Prediction p : predictions) {
            if (p.getProbability() > threshold) {   // the core rule: >0.85
                alerts.add(p);
            }
        }
        return alerts;
    }

    public double getThreshold() {
        return threshold;
    }
}