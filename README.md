# multiple_regression_lda
Code (Multiple Regression LDA) and data described in the paper:
**T. Kusmierczyk, K. Nørvåg: Online Food Recipe Title Semantics: Combining Nutrient Facts and Topics. CIKM 2016.**

## Model  
We propose a model
that uses the latent topic space to explain both observed words and
related real values.
Among latent topic models, the most popular is latent dirichlet
allocation (LDA). 
We adopt LDA by extending it with multiple linear
regression components.
Linear regression is a well established statistical technique where
dependent variables are modeled as a weighted sum of explanatory
variables and bias.
In our model explanatory variables are LDA topic distributions per document.

## Application
Dietary pattern analysis is an important research area, and recently
the availability of rich resources in food-focused social networks
has enabled new opportunities in that field. However, there is a little 
understanding of how online textual content is related to actual
health factors, e.g., nutritional values. To contribute to this lack of
knowledge, we present a novel approach to mine and model online
food content by combining text topics with related nutrient facts.
Our empirical analysis reveals a strong correlation between them
and our experiments show the extent to which it is possible to 
predict nutrient facts from meal name

## Data (only sample provided)
Our study relies on the data retrieved from the largest English
online food recipe platform, namely allrecipes.com. The web site
was crawled and archived in July 2015, and the data set contains
more than 240 thousand recipes. 
For each recipe, metadata with title and information about nutritional
 facts (per 100 g) are provided. Unfortunately, some nutrient
values were missing for the majority of recipes, and all seven of the
most important facts (i.e., kilocalories (denote kcal), fat, carbohydrates
 (denote carbo), proteins, sugars, sodium, cholesterol) were
present in only 58 thousand recipes. Thus, our experiments focused
on this subset.
Initially, recipe titles were arbitrary strings defined as free-form
text by the users. Several standard text pre-processing, data cleaning
 steps were necessary. First, we filtered out punctuation, special
characters, numbers and stop-words. Then, using a Porter stemmer,
word forms were unified. Finally, we filtered out all words occurring
 less than 2 times in the corpus. This procedure resulted in a
vocabulary containing of 4,679 unique words.

