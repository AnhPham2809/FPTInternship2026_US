package com.fpt.alertservice;

import java.util.List;

/**
 * The flow:
 *   1. BigQueryClient fetches predictions
 *   2. AlertService evaluates each row against the 0.85 threshold
 *   3. AlertNotifier writes alerts to stdout
 */
public class Main {

    public static void main(String[] args) throws InterruptedException {

        double threshold = 0.85;   // the alert threshold from the spec

        // Build the pieces (each class does one job)
        BigQueryClient client = new BigQueryClient();
        AlertService alertService = new AlertService(threshold);
        AlertNotifier notifier = new AlertNotifier();

        System.out.println("Fetching predictions from BigQuery...");
        List<Prediction> predictions = client.fetchPredictions();   // network call - not timed
        int rowCount = predictions.size();
        System.out.println("Fetched " + rowCount + " predictions.\n");

        //TIME THE EVALUATION (the "row evaluation" the spec refers to)
        // This is the pure decision logic: check each row against the threshold.
        long startTime = System.nanoTime();
        List<Prediction> alerts = alertService.findAlerts(predictions);
        long endTime = System.nanoTime();

        double totalMs = (endTime - startTime) / 1_000_000.0;         // whole batch, ms
        double perRowMs = totalMs / rowCount;                         // per-row, ms
        

        // Print a few sample alerts (not all - printing thousands is slow and noisy)
        System.out.println("Sample alerts (showing first 5 of " + alerts.size() + "):");
        int shown = 0;
        for (Prediction alert : alerts) {
            notifier.sendAlert(alert);
            if (++shown >= 5) break;
        }

        // RESULTS
        System.out.println("\n--- Summary ---");
        System.out.println("Rows evaluated:        " + rowCount);
        System.out.println("Alerts fired (>0.85):  " + alerts.size());
        System.out.printf ("Total evaluation time: %.2f ms%n", totalMs);
        System.out.printf ("Per-row evaluation:    %.5f ms%n", perRowMs);

        if (perRowMs < 200) {
            System.out.println("PASS: per-row evaluation well under 200ms.");
        } else {
            System.out.println("SLOW: per-row evaluation over 200ms.");
        }
    }
}