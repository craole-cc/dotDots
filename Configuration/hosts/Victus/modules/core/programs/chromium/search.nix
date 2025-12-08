{
  programs.chromium = {
    homepageLocation = "https://www.perplexity.ai";
    defaultSearchProviderEnabled = true;
    defaultSearchProviderSearchURL = "https://www.perplexity.ai/search?q=%s";
    defaultSearchProviderSuggestURL = "https://encrypted.google.com/complete/search?output=chrome&q={searchTerms}";
    searchEngines = {
      perplexity = {
        name = "Perplexity AI";
        url = "https://www.perplexity.ai/search?q=%s";
        isDefault = true;
      };
    };
  };
}
