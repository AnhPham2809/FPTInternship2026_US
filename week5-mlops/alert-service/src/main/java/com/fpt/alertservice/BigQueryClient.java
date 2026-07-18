package com.fpt.alertservice;

import com.google.cloud.bigquery.BigQuery;
import com.google.cloud.bigquery.BigQueryOptions;
import com.google.cloud.bigquery.QueryJobConfiguration;
import com.google.cloud.bigquery.TableResult;
import com.google.cloud.bigquery.FieldValueList;

import java.util.ArrayList;
import java.util.List;

/**
 * BigQueryClient - handles all communication with BigQuery.
 * Connect to BigQuery, run a query, and return Prediction objects.
 */
public class BigQueryClient {

    private final BigQuery bigquery;   // the BigQuery connection

    // Constructor - opens the connection to our GCP project
    public BigQueryClient() {
        this.bigquery = BigQueryOptions.newBuilder()
                .setProjectId("fpt-internship-2026")
                .build()
                .getService();
    }

    /**
     * Fetches all predictions from the bot_predictions view.
     * Returns a list of Prediction objects for the rest of the app to use.
     */
    public List<Prediction> fetchPredictions() throws InterruptedException {
        // The SQL we want BigQuery to run
        String query =
            "SELECT edit_id, model_name, probability " +
            "FROM `fpt-internship-2026.wikimedia_data.bot_predictions`";

        QueryJobConfiguration config = QueryJobConfiguration.newBuilder(query).build();

        // Run the query and get results back
        TableResult result = bigquery.query(config);

        // Convert each BigQuery row into a Prediction object
        List<Prediction> predictions = new ArrayList<>();
        for (FieldValueList row : result.iterateAll()) {
            String editId = row.get("edit_id").getStringValue();
            String modelName = row.get("model_name").getStringValue();
            double probability = row.get("probability").getDoubleValue();
            predictions.add(new Prediction(editId, modelName, probability));
        }

        return predictions;
    }
}