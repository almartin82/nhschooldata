# Extract a column using multiple possible names

Searches for a column in the data frame using several possible name
variants. Returns NA if none of the names match.

## Usage

``` r
extract_column(df, possible_names)
```

## Arguments

- df:

  Data frame to search

- possible_names:

  Character vector of possible column names

## Value

Character vector from the matched column, or NA vector
