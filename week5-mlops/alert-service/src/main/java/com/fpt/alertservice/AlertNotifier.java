package com.fpt.alertservice;

import java.util.List;

/**
 * AlertNotifier - handles OUTPUT only.
 */
public class AlertNotifier {

    /**
     * Writes each alert to standard output.
     */
    public void sendAlerts(List<Prediction> alerts) {
        if (alerts.isEmpty()) {
            System.out.println("No high-confidence predictions above threshold.");
            return;
        }

        for (Prediction alert : alerts) {
            // The alert message written to stdout
            System.out.println("ALERT: high-confidence "
                + alert.getModelName() + " prediction - "
                + "edit " + alert.getEditId()
                + " (probability " + String.format("%.4f", alert.getProbability()) + ")");
        }
    }
    
    /**
     * Writes a single alert to standard output.
     */
    public void sendAlert(Prediction alert) {
        System.out.println("ALERT: high-confidence "
            + alert.getModelName() + " prediction - "
            + "edit " + alert.getEditId()
            + " (probability " + String.format("%.4f", alert.getProbability()) + ")");
    }
}