package com.fpt.alertservice;

/**
 * Prediction - represents ONE prediction row from BigQuery.
 * Just holds data: which edit, which model, and the probability score.
 * This is a plain data class - it has no logic, it only stores values.
 */
public class Prediction {

    private final String editId;      // which edit this prediction is about
    private final String modelName;   // 'bot' or 'minor'
    private final double probability; // the model's confidence, 0.0 to 1.0

    // Constructor - how you create a Prediction object
    public Prediction(String editId, String modelName, double probability) {
        this.editId = editId;
        this.modelName = modelName;
        this.probability = probability;
    }

    // Getters - how other classes read the values (read-only, kept private above)
    public String getEditId() {
        return editId;
    }

    public String getModelName() {
        return modelName;
    }

    public double getProbability() {
        return probability;
    }

    // A readable text version, useful for printing alerts later
    @Override
    public String toString() {
        return "Edit " + editId + " | model=" + modelName + " | probability=" + probability;
    }
}