- Univariate statistics: analyzing one predictor at a time.
- Multivariate statistics: analyzing several variables together.
- Correlation and regression: measuring relationships and controlling for other variables.

False positives and false negatives belong more specifically to classification evaluation or diagnostic testing. They come from a confusion matrix:

                         Actually positive      Actually negative
━━━━━━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━
 Predicted positive     True positive (TP)    False positive (FP)
────────────────────  ─────────────────────  ─────────────────────
 Predicted negative    False negative (FN)     True negative (TN)

Common divisions you may be remembering:

- Accuracy = (TP + TN) / all cases
  How often was the prediction correct overall?

- Precision = TP / (TP + FP)
  Of the positive predictions, how many were right?

- Recall / sensitivity / true-positive rate = TP / (TP + FN)
  Of the actual positives, how many did we find?

- Specificity = TN / (TN + FP)
  Of the actual negatives, how many did we reject correctly?

- False-positive rate = FP / (FP + TN)
- False-negative rate = FN / (FN + TP)

- Precision asks: “Of the queries we flagged as expensive, how many really were?”
- Recall/hit rate asks: “Of all truly expensive queries, how many did we flag?”

