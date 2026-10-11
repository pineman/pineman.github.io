confusion matrix (classifiers, diagnostic tests):

|                        | Actually positive   | Actually negative   |
|------------------------|---------------------|---------------------|
| **Predicted positive** | True positive (TP)  | False positive (FP) |
| **Predicted negative** | False negative (FN) | True negative (TN)  |

<dl>
  <dt><strong>Accuracy</strong></dt>
  <dd>How often was the prediction correct overall?</dd>
  <dd><code>(TP + TN) / (TP + TN + FP + FN)</code></dd>
  <dt><strong>Precision / Positive Predictive Value</strong> (PPV)</dt>
  <dd>Of the positive predictions, how many were right?</dd>
  <dd><code>TP / (TP + FP)</code></dd>
  <dt><strong>Negative Predictive Value</strong> (NPV)</dt>
  <dd>Of the negative predictions, how many were right?</dd>
  <dd><code>TN / (TN + FN)</code></dd>
  <dt><strong>True positive rate</strong> (Recall / Sensitivity / Hit rate / Power)</dt>
  <dd>Of the actual positives, how many did we find?</dd>
  <dd><code>TP / (TP + FN)</code></dd>
  <dt><strong>True negative rate</strong> (Specificity)</dt>
  <dd>Of the actual negatives, how many did we reject correctly?</dd>
  <dd><code>TN / (TN + FP)</code></dd>
  <dt><strong>False positive rate</strong> (Fall-out)</dt>
  <dd><code>FP / (FP + TN)</code></dd>
  <dt><strong>False negative rate</strong> (Miss rate)</dt>
  <dd><code>FN / (FN + TP)</code></dd>
</dl>
