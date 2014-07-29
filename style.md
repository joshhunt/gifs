## One liners
'One liners' are ok, especially for things like promises and underscore.js, but use your best judgement to avoid overly complex and hard-to-read lines.

For example, these are ok:

```
images = _.chain allArticles
    .filter (article) -> article.hasMedia
    .map    (article) -> article.image
```