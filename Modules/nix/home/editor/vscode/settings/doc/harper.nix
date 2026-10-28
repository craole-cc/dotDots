{
  context,
  mkEnable,
  requires,
  ...
}: let
  lang = "harper";
  condition = requires lang;
  enable = condition;
  options.${lang}.enable = mkEnable {inherit context condition;};

  #? Prose grammar + style linter (Harper `harper-ls`)
  defaultFormatter = "elijah-potter.harper";
  extensions = [defaultFormatter];

  settings.${lang} = {
    #~@ Top-level Settings
    #> Stable code action positions: puts "always available" actions
    #> (e.g. add-to-dictionary) first.
    codeActions.ForceStable = false;

    #> Diagnostic severity in the editor.
    #? - error | warning | information | hint
    diagnosticSeverity = "information";

    #> English dialect. Drives which spelling is considered correct.
    #? - American | British | Australian | Canadian
    dialect = "British"; #! overridden (default: "American")

    #> Globs to skip. Files matching any are not linted.
    excludePatterns = [];

    #> Path to a file dictionary directory. Empty = none.
    fileDictPath = "";

    #> Only lint English text in mixed-language documents.
    isolateEnglish = false;

    #> Skip linting link titles in Markdown.
    markdown.IgnoreLinkTitle = false;

    #> Maximum file size (bytes) to lint. Larger files are skipped.
    maxFileLength = 120000;

    #> Path to a `harper-ls` executable. Empty = bundled.
    path = "";

    #> Path to a user dictionary file. Empty = none.
    userDictPath = "";

    #> Path (relative to workspace root) to a per-repo dictionary.
    #! overridden (default: "")
    workspaceDictPath = ".harper-dictionary.txt";

    linters = {
      #~@ Linter Rules
      /**
      #> Per-rule on/off flags. Rule id = suffix after `harper.linters.`.
      #?  true  = rule active (report diagnostics)
      #?  false = rule disabled
      #! overridden (defaults: all rules active)

      #> Regenerate from upstream (exact list for your Harper version):
      ```sh
      curl -s 'https://api.github.com/repos/Automattic/harper/contents/harper-core/src/linting?ref=master' |
        jq -r '.[] |
        select(.type=="file") |
        .name |
        sub("\\.rs$";"") |
        select(. != "mod") |
        split("_") |
        map(ascii_upcase[0:1] + .[1:]) |
        join("")' |
        sort |
        awk '{print "# \"harper.linters." $0 "\" = true;"}'
      ```
      */

      #> Corrects `accuse for` to `accuse of`.
      AccuseOf = true;
      #> Corrects `a couple of more` to `a couple more`.
      ACoupleMore = true;
      #> Replaces `addicting` with `addictive` when used as an adjective.
      Addicting = true;
      #> Finds adjectives used with a double degree (`more prettier`).
      AdjectiveDoubleDegree = true;
      #> Looks for sequences of words of the form `adjective of a`.
      AdjectiveOfA = true;
      #> Corrects `as nauseam` to `ad nauseam`.
      AdNauseam = true;
      #> Corrects `adieu` to `ado`.
      Ado = true;
      #> Corrects the missing `of` in `take advantage of`.
      AdvantageOf = true;
      #> Corrects `afterall` to `after all`.
      AfterAll = true;
      #> Corrects missing article in `after while` → `after a while`.
      AfterAWhile = true;
      #> Checks for `later` following `after [period]`.
      AfterLater = true;
      #> Corrects `an` to `and` after `ahead`.
      AheadAnd = true;
      #> Corrects `a jar` to `ajar`.
      Ajar = true;
      #> Corrects `a kimbo` to `akimbo`.
      Akimbo = true;
      #> Corrects to `albeit`.
      Albeit = true;
      #> Corrects `a little of practice` to `a little practice`.
      ALittleOfPractice = true;
      #> Corrects `all hell breaks out` to `all hell breaks loose`.
      AllHellBreakLoose = true;
      #> Corrects wrong forms of `for all intents and purposes`.
      AllIntentsAndPurposes = true;
      #> Guides toward `all of a sudden`.
      AllOfASudden = true;
      #> Flags `allow to` without a subject.
      AllowTo = true;
      #> Flags `all ready` before an adjective (→ `already`).
      AllReady = true;
      #> Flags `all though` (→ `although`).
      AllThough = true;
      #> Corrects `all well in good` to `all well and good`.
      AllWellAndGood = true;
      #> Replaces `along side` with `alongside`.
      Alongside = true;
      #> Corrects `along time` to `a long time`.
      ALongTime = true;
      #> Fixes `old-timers' disease` to `Alzheimer’s disease`.
      AlzheimersDisease = true;
      #> Amazon product names must be proper nouns.
      AmazonNames = true;
      #> Corrects `a mean to an end` to `a means to an end`.
      AMeansToAnEnd = true;
      #> Americas must be proper nouns.
      Americas = true;
      #> Flags redundant am/pm + period indicators (`9 AM in the morning`).
      AmInTheMorning = true;
      #> Corrects `amounts for` to `amounts to` / `accounts for`.
      AmountsFor = true;
      #> Flags incorrect indefinite articles (`an mule`).
      AnA = true;
      #> Suggests standard terms for `analog bike` / `acoustic bike`.
      #! default: false
      AnalogAcousticBike = false;
      #> Corrects `an another` / `a another`.
      AnAnother = true;
      #> Fixes `an in` standing in for `and in`.
      AndIn = true;
      #> Corrects `and the such` to `and such`.
      AndSuch = true;
      #> Corrects `and the like` / `or the like`.
      AndTheLike = true;
      #> Corrects `another an` to `another`.
      AnotherAn = true;
      #> Corrects `another ones`.
      AnotherOnes = true;
      #> `another thing coming` is now more common than `another think coming`.
      AnotherThingComing = true;
      #> Corrects `another things`.
      AnotherThings = true;
      #> `another think coming` is the original phrase (vs. `another thing`).
      #! default: false
      AnotherThinkComing = false;
      #> Fixes spacing inside `anybody`.
      Anybody = true;
      #> Fixes spacing inside `anyhow`.
      Anyhow = true;
      #> Fixes spacing inside `anywhere`.
      Anywhere = true;
      #> Hyphenates `A-OK` when used adjectivally.
      AOkHyphen = true;
      #> Distinguishes `a part` from `apart`.
      APart = true;
      #> Fixes `apart form` → `apart from`.
      ApartFrom = true;
      #> Apple product/service names must be proper nouns.
      AppleNames = true;
      #> Corrects `argument to be said` → `argument to be made`.
      ArgumentToBeMade = true;
      #> Prefers `arrive on Friday` over bare weekday.
      ArriveOnWeekday = true;
      #> Corrects `arrive to` → `arrive at`/`arrive in`.
      ArriveTo = true;
      #> Corrects `as compare to` → `as compared to`.
      AsComparedTo = true;
      #> Corrects `evident by` → `evidenced by`.
      AsEvidentBy = true;
      #> Expands initialism `AFAICT`.
      AsFarAsICanTell = true;
      #> Expands initialism `AFAIK`.
      AsFarAsIKnow = true;
      #> Corrects `as early back as` → `as far back as`.
      AsFarBackAs = true;
      #> Corrects `as follow` → `as follows`.
      AsFollows = true;
      #> Corrects `as how` → `as to how`.
      AsHow = true;
      #> Corrects redundant `as if though`.
      AsIfThough = true;
      #> Flags `as is with anything` → `as with anything`.
      AsIsWithAnything = true;
      #> Corrects `as it so happens` → `as it happens`.
      AsItHappens = true;
      #> Expands initialism `AIUI`.
      AsIUnderstandIt = true;
      #> Flags `ask to us` / `tell to him` (superfluous `to`).
      AskNoPreposition = true;
      #> Corrects `aslong as` / `as long that` → `as long as`.
      AsLongAs = true;
      #> Corrects `as much than` → `as much as`.
      AsMuchAs = true;
      #> Corrects `as of currently` → `currently` / `as of now`.
      AsOfCurrently = true;
      #> Corrects `as of lately` → `lately` / `as of late`.
      AsOfLately = true;
      #> Removes redundant `a some time`.
      ASomeTime = true;
      #> Corrects `as oppose to` → `as opposed to`.
      AsOpposedTo = true;
      #> Corrects `aspire for` → `aspire to`.
      AspireTo = true;
      #> Expands initialism `ASAP`.
      AsSoonAsPossible = true;
      #> Corrects `to` → `as to` between adjectives and wh-words.
      AsToInterrogative = true;
      #> Corrects `at all cost` → `at all costs`.
      AtAllCosts = true;
      #> Corrects nonstandard variants of `at face value`.
      AtFaceValue = true;
      #> Fixes typo `at leas` → `at least`.
      AtLeasToLeast = true;
      #> Fixes typo `at lest` → `at least`.
      AtLestToLeast = true;
      #> Corrects `in the best of times` → `at the best of times`.
      AtTheBestOfTimes = true;
      #> Corrects `in the end of the day` → `at the end of the day`.
      AtTheEndOfTheDay = true;
      #> Corrects `at the expanse of` → `at the expense of`.
      AtTheExpenseOf = true;
      #> Corrects `in the very least` → `at the very least`.
      AtTheVeryLeast = true;
      #> Corrects `hearable` → `audible`.
      Audible = true;
      #> Australian states/territories/cities must be proper nouns.
      Australia = true;
      #> Reduces `and also` → `and`.
      AvoidAndAlso = true;
      #> Suggests expanded forms for contractions.
      #! default: false
      AvoidContractions = false;
      #> Flags offensive language, offers euphemisms.
      AvoidCurses = true;
      #> Suggests `await` or `wait for` — not both.
      AwaitFor = true;
      #> Corrects `aware about` → `aware of`.
      AwareOf = true;
      #> Corrects idiom `a ways to go` (missing article).
      AWaysToGo = true;
      #> Enforces `awhile` after verbs, `a while` elsewhere.
      AWhile = true;
      #> Corrects `a whole another` → `a whole other`.
      AWholeOther = true;
      #> Azure product names must be proper nouns.
      AzureNames = true;
      #> Corrects `backhand compliment` → `backhanded compliment`.
      BackhandedCompliment = true;
      #> Flags `back in the days` → `back in the day`.
      BackInTheDay = true;
      #> Fixes spacing inside `backplane`.
      Backplane = true;
      #> Changes `bed rap` → `bad rap`.
      BadRap = true;
      #> Distinguishes `bain` from `bane`.
      BainBane = true;
      #> Corrects `ban together` → `band together`.
      BanTogether = true;
      #> Corrects `bare-bone` → `bare-bones`.
      BareBones = true;
      #> Ensures `bear in mind` (not `bare in mind`).
      BareInMind = true;
      #> Flags `barely unusable` (double negative).
      BarelyUn = true;
      #> Corrects `bare with` → `bear with`.
      BareWithMe = true;
      #> Changes `baited breath` → `bated breath`.
      BatedBreath = true;
      #> Ensures passive `be allowed` after future negatives.
      BeAllowed = true;
      #> Detects `be + verb` where `be + adjective` fits (`be biased`).
      BeBiased = true;
      #> Fixes eggcorns of `beck and call`.
      BeckAndCall = true;
      #> Detects `be + verb` where `be + adjective` fits (`be concerned`).
      BeConcerned = true;
      #> Corrects `bee there` → `been there`.
      BeenThere = true;
      #> Enforces one-word `beforehand`.
      Beforehand = true;
      #> Corrects `behind the scene` → `behind the scenes`.
      BehindTheScenes = true;
      #> Flags `bellow` for `below`.
      BellowBelow = true;
      #> Detects `be + verb` where `be + adjective` fits (`be prejudiced`).
      BePrejudiced = true;
      #> Expands initialism `BRB`.
      BeRightBack = true;
      #> Detects `be + verb` where `be + adjective` fits (`be shocked`).
      BeShocked = true;
      #> Corrects `besides the point` → `beside the point`.
      BesideThePoint = true;
      #> Corrects `of all times` → `of all time` in superlatives.
      BestOfAllTime = true;
      #> Corrects `beat regards` → `best regards`.
      BestRegards = true;
      #> Rewrites `better of` → `better off` in comparatives.
      BetterOffPhrase = true;
      #> Corrects `better off served` → `better off`/`better served`.
      BetterOffServed = true;
      #> Corrects `better of with` → `better off with`.
      BetterOffWith = true;
      #> Enforces `beware of` (not other prepositions).
      BewareOf = true;
      #> Detects `be + verb` where `be + adjective` fits (`be worried`).
      BeWorried = true;
      #> Normalizes `black list` / `white list` → compound.
      BlacklistWhitelist = true;
      #> Fixes common errors in `blanket statement`.
      BlanketStatement = true;
      #> Enforces `Blu-ray` hyphenation.
      BluRayHyphen = true;
      #> Flags `boarder` (lodger) → `border` (edge).
      BoarderBorder = true;
      #> Corrects `bullocks` → `bollocks` (nonsense).
      Bollocks = true;
      #> Flags overused "boring" words.
      #! default: false
      BoringWords = false;
      #> Replaces `bough` → `bought` after subject pronouns.
      Bought = true;
      #> Flags `brandish` for `brand`.
      BrandBrandish = true;
      #> Suggests `brutality` (more common).
      Brutality = true;
      #> Enforces `built-in` as one word.
      BuiltIn = true;
      #> Corrects `by accident` (idiom).
      ByAccident = true;
      #> Corrects `by extent` → `by extension`.
      ByExtension = true;
      #> Fixes `by my own` → `on my own`/`by myself`.
      ByOnesOwn = true;
      #> Fixes spacing inside `bypass`.
      Bypass = true;
      #> Corrects `by the books` → `by the book`.
      ByTheBook = true;
      #> Expands initialism `BTW`.
      ByTheWay = true;
      #> Corrects wrong variants of `call it quits`.
      CallItQuits = true;
      #> Addresses non-idiomatic `call them as`.
      CallThem = true;
      #> Canadian provinces/territories/cities must be proper nouns.
      Canada = true;
      #> Corrects `can be seem` → `can be seen`.
      CanBeSeen = true;
      #> Suggests `can't` for `cant`.
      Cant = true;
      #> Corrects `way` → `wait` in `can't way to` etc.
      CantWay = true;
      #> "Capitalize on" — collection run as one.
      CapitalizeOn = true;
      #> Requires capitalisation of `I`, `I'm`, etc.
      CapitalizePersonalPronouns = true;
      #> Corrects `case and point` → `case in point`.
      CaseInPoint = true;
      #> Hyphenates `case-sensitive`.
      CaseSensitive = true;
      #> Corrects soundalike confusion in `catch 22`.
      Catch22 = true;
      #> Normalises `cause it is` → standard subordinating form.
      CauseItIsBecause = true;
      #> Distinguishes `tale` (story) from `tail` (appendage).
      CautionaryTale = true;
      #> Catches `seize to` (typo for `cease to`).
      CeaseTo = true;
      #> Fixes spacing inside `chalkboard`.
      Chalkboard = true;
      #> Corrects `chomp at the bit` → `champ at the bit`.
      ChampAtTheBit = true;
      #> Corrects `change tack` idiom variants.
      ChangeTack = true;
      #> Corrects wrong variants of `chicken-and-egg`.
      ChickenAndEgg = true;
      #> CCP name must be a proper noun.
      ChineseCommunistParty = true;
      #> Corrects soundalikes of `chock-full`; enforces hyphen.
      ChockFull = true;
      #> Corrects `claim for fame` → `claim to fame`.
      ClaimToFame = true;
      #> Cliché collection (`accent`).
      ClicheAccent = true;
      #> Hyphenates `click-through-rate` in analytics contexts.
      ClickThroughRate = true;
      #> Corrects `client's side` → `client-side`.
      ClientOrServerSide = true;
      #> Corrects `close-nit`/`tight-nit` → `close-knit`/`tight-knit`.
      CloseTightKnit = true;
      #> Fixes spacing inside `codebase`.
      Codebase = true;
      #> Fixes spacing inside `codebases`.
      Codebases = true;
      #> Corrects `code on` → `code in` (writing code).
      CodeInWriteIn = true;
      #> Rewrites `cold` → `could` in modal contexts.
      ColdModalTypo = true;
      #> Corrects `comfortable of` → `comfortable with`.
      ComfortableWith = true;
      #> Fixes comma spacing, `，` for `,`, etc.
      CommaFixes = true;
      #> Corrects `commitment toward` → `commitment to`.
      CommitmentTo = true;
      #> Ensures proper capitalisation of companies/brands.
      CompaniesProductsAndTrademarks = true;
      #> Corrects `complain` used as a noun.
      ComplainAsNoun = true;
      #> Merges split compound nouns.
      CompoundNouns = true;
      #> Promotes `I` in compound subjects with a possessive determiner.
      CompoundSubjectI = true;
      #> `Comprises` already contains `of`.
      ComprisesOf = true;
      #> Suggests `compel` for `compulse`.
      CompulseToCompel = true;
      #> Suggests `condense` for `condensate` (verb).
      CondensateVerb = true;
      #> Suggests `all the` for `all of the`.
      CondenseAllThe = true;
      #> Corrects `confidant` → `confident` (adjective).
      Confident = true;
      #> Corrects `conform` typos → `confirm`.
      ConfirmThat = true;
      #> Removes extraneous `as` after `constitute`.
      ConstituteAs = true;
      #> Corrects `convenient store` → `convenience store`.
      ConvenientStore = true;
      #> Corrects `copywrite` → `copyright`.
      Copyright = true;
      #> Catches mismatched number suffixes (`2st`).
      CorrectNumberSuffix = true;
      #> Country names must be proper nouns.
      Countries = true;
      #> `Coursing` (flowing) vs eggcorn `cursing` through veins.
      CoursingThroughVeins = true;
      #> Removes `for` after `crave`.
      CraveFor = true;
      #> `criteria`/`phenomena` are plural forms.
      CriteriaPhenomena = true;
      #> Enforces `cross-platform` hyphenation.
      CrossPlatform = true;
      #> Prefers `cure for`.
      CureFor = true;
      #> Corrects `curious of`/`curious on` → `curious about`.
      CuriousAbout = true;
      #> Corrects improper placement of currency symbols.
      CurrencyPlacement = true;
      #> Corrects `cutting age` → `cutting-edge`.
      CuttingAgeEggcorn = true;
      #> Expands `cybersec` → `cybersecurity`.
      Cybersec = true;
      #> Checks plural `damages` outside legal context.
      Damages = true;
      #> Corrects `damp squid` → `damp squib`.
      DampSquib = true;
      #> Writers often type `--` or `---` expecting their editor to convert them into proper dashes. Replace these sequences with the correct characters: use an en dash (–) for ranges or connections and an em dash (—) for a break in thought.
      Dashes = false; #! overridden
      #> Corrects blended `date back from`.
      DateBackFrom = true;
      #> Fixes `in this day and age` variants.
      DayAndAge = true;
      #> Day One brand names must be proper nouns.
      DayOneNames = true;
      #> Fixes spacing inside `deadlift`.
      Deadlift = true;
      #> `the` is a definite article.
      DefiniteArticle = true;
      #> Corrects `degrees kelvin` → `kelvins`.
      DegreesKelvin = true;
      #> Corrects `°K` → `K`.
      DegreesKelvinSymbol = true;
      #> Corrects `deny offer` → `decline`/`reject`.
      DenyOffer = true;
      #> Dereference collection.
      Dereference = true;
      #> Fixes spacing inside `desktop`.
      Desktop = true;
      #> Corrects wrong form of `is` after `despite`.
      DespiteItIs = true;
      #> Corrects `despite of` → `despite`/`in spite of`.
      DespiteOf = true;
      #> Fixes spacing inside `devops`.
      Devops = true;
      #> Corrects `dint` → `didn't` after subject pronouns.
      Didnt = true;
      #> Uses base form of verbs with `did`.
      DidPast = true;
      #> Corrects `digestive track` → `digestive tract`.
      DigestiveTract = true;
      #> Flags mixed metaphor `digging under the hood`.
      DigUnderTheHood = true;
      #> Requires comma after discourse markers at sentence start.
      DiscourseMarkers = true;
      #> Removes `about` after `discuss`.
      Discuss = true;
      #> Joins prefixed words that were split with a space.
      DisjointPrefixes = true;
      #> Distinguishes `dissemble` from `disassemble`.
      DissembleDisassemble = true;
      #> Corrects typos of `dose` → `does`.
      DoesOrDose = true;
      #> Swaps `do` → `am` in `Do I <adjective>` questions.
      DoIAdjective = true;
      #> Corrects `do a mistake` → `make a mistake`.
      DoMistake = true;
      #> Flags truncation `wan` (from `want`).
      DoNotWant = true;
      #> Corrects `don't can` → `can't`/`cannot`.
      DontCan = true;
      #> Ensures proper dot-separated initialisms.
      DotInitialisms = true;
      #> Corrects `do to` → `due to` in causal phrases.
      DoToDueTo = true;
      #> Normalises `double check` → `double-check`.
      DoubleCheckHyphen = true;
      #> Enforces `double-click` hyphen.
      DoubleClick = true;
      #> Corrects `double-edged sword` variants.
      DoubleEdgedSword = true;
      #> Flags two modals in a row.
      DoubleModal = true;
      #> Collapses double negation (`didn't have no` → `any`).
      DoubleNegative = true;
      #> Corrects `do diligence` → `due diligence`.
      DueDiligence = true;
      #> Prefers `for ages`.
      DuringAges = true;
      #> Corrects `each and everyone` → `each and every one`.
      EachAndEveryOne = true;
      #> Rewrites `each others` → `each other's`.
      EachOthersPossessive = true;
      #> Hyphenates `eagle-eyed` as compound modifier.
      EagleEyed = true;
      #> Hyphenates `easy-going` before nouns.
      EasyGoingCompoundAdjective = true;
      #> Corrects `egg yoke` → `egg yolk`.
      EggYolk = true;
      #> Validates number of dots in an ellipsis.
      EllipsisLength = true;
      #> Corrects missing apostrophe in `someone elses`.
      ElsePossessive = true;
      #> Corrects `eluded to` → `alluded to`.
      EludedTo = true;
      #> Suggests `en masse` for `on mass`/`in mass`.
      EnMasse = true;
      #> Suggests `en route` for `on route`/`in route`.
      EnRoute = true;
      #> Environment variable naming.
      EnvironmentVariable = true;
      #> Corrects typos of `every` → `ever`.
      EverEvery = true;
      #> Hyphenates `ever-present`.
      EverPresent = true;
      #> Removes redundant relative pronoun after `whatever`/`whoever`.
      EverPronounRelPronoun = true;
      #> Corrects `every since` → `ever since`.
      EverSince = true;
      #> Fixes spacing inside `everybody`.
      Everybody = true;
      #> Distinguishes `everyday` from `every day`.
      Everyday = true;
      #> Corrects `every once and again`.
      EveryOnceAndAgain = true;
      #> Fixes spacing inside `everyone`.
      Everyone = true;
      #> Detects missing `one` in `every single one of`.
      EverySingleOneOf = true;
      #> Corrects `everytime` → `every time`.
      EveryTime = true;
      #> Fixes spacing inside `everywhere`.
      Everywhere = true;
      #> Prefers `excellent` over `very good`.
      Excellent = true;
      #> Corrects `except of` → `except for`.
      ExceptOf = true;
      #> Changes `exited` → `excited` in enthusiasm contexts.
      ExitedExcitedContext = true;
      #> Expands `algo` → `algorithm`.
      ExpandAlgorithm = true;
      #> Expands `alloc` → `allocate`/`allocation`.
      ExpandAlloc = true;
      #> Expands `arg` → `argument`.
      ExpandArgument = true;
      #> Expands `cuz` → `because`.
      ExpandBecause = true;
      #> Configuration expansion collection.
      ExpandConfiguration = true;
      #> Expands `ctrl` → `control`.
      ExpandControl = true;
      #> Expands `coord` → `coordinate`.
      ExpandCoordinate = true;
      #> Expands `decl` → `declaration`/`declarator`.
      ExpandDecl = true;
      #> Expands `deps` → `dependencies`.
      ExpandDependencies = true;
      #> Expands `deref` → `dereference`.
      ExpandDereference = true;
      #> Expands `dir` → `directory`.
      ExpandDirectory = true;
      #> Expands `fav`/`fave` → `favorite`/`favourite`.
      ExpandFavourite = true;
      #> Expands `fwd` → `forward`.
      ExpandForward = true;
      #> Expands `govt` → `government`.
      ExpandGovt = true;
      #> Expands `legit` → `legitimate`.
      ExpandLegitimate = true;
      #> Expands memory shorthand (`MB` → `megabyte`, etc.).
      ExpandMemoryShorthands = true;
      #> Expands `min` → `minimum`.
      ExpandMinimum = true;
      #> Expands `notif` → `notification`.
      ExpandNotification = true;
      #> Expands `param` → `parameter`.
      ExpandParameter = true;
      #> Expands `ppl` → `people`.
      ExpandPeople = true;
      #> Expands `perf` → `performance`.
      ExpandPerformance = true;
      #> Expands `ptr` → `pointer`.
      ExpandPointer = true;
      #> Preference expansion collection.
      ExpandPreference = true;
      #> Expands `prev` → `previous`.
      ExpandPrevious = true;
      #> Expands `stdin`/`stdout`/`stderr`.
      ExpandStandardInputAndOutput = true;
      #> Expands `tho` → `though`.
      ExpandThough = true;
      #> Expands `thru` → `through`.
      ExpandThrough = true;
      #> Expands `hr`/`min`/`sec`/etc.
      ExpandTimeShorthands = true;
      #> Expands `vuln` → `vulnerability`.
      ExpandVulnerability = true;
      #> Expands `w/` → `with`.
      ExpandWith = true;
      #> Expands `w/o` → `without`.
      ExpandWithout = true;
      #> Fixes split `expat`.
      Expat = true;
      #> Fixes `expatriate` misuse.
      Expatriate = true;
      #> Expands initialism `ELI5`.
      ExplainLikeImFive = true;
      #> Corrects `explanation mark` → `exclamation mark`.
      ExplanationMark = true;
      #> Corrects `extend` → `extent` in noun contexts.
      ExtendOrExtent = true;
      #> Hyphenates `face-first`.
      FaceFirst = true;
      #> Fixes malapropisms of `a fair bit`.
      FairBit = true;
      #> Flags redundant `below` after fall distances.
      FallBelow = true;
      #> Corrects `far and few between` → `few and far between`.
      FarAndFewBetween = true;
      #> Flags `far be it` (missing `from`).
      FarBeIt = true;
      #> Ensures correct prepositions for `fascinated`.
      FascinatedBy = true;
      #> Detects `fast paste` → `fast-paced`.
      FastPaste = true;
      #> Replaces `fatal outcome` → `death`.
      FatalOutcome = true;
      #> Corrects `fed up of` → `fed up with` (non-British).
      FedUpWith = true;
      #> Corrects `fell` → `feel` expressions.
      FeelFell = true;
      #> Corrects redundant `fellow` + `co-`.
      FellowCoRedundancy = true;
      #> Ensures `fetal position` (not `feeble position`).
      FetalPosition = true;
      #> Corrects `few` → `a few` before time units.
      FewUnitsOfTimeAgo = true;
      #> Removes filler words.
      FillerWords = true;
      #> Fixes `find` → `fine`.
      FindFine = true;
      #> Flags `find out` where `find` is better.
      FindOut = true;
      #> Corrects `finish touches` → `finishing touches`.
      FinishingTouches = true;
      #> Detects `first aid kid` (should be `kit`).
      FirstAidKit = true;
      #> Hyphenates ordinal-person modifiers.
      FirstPersonModifierHyphen = true;
      #> Corrects `neither fish nor foul` → `neither fish nor fowl`.
      FishNorFowl = true;
      #> Corrects `flaunt` → `flout` with rule-like nouns.
      FlauntForFlout = true;
      #> Corrects `flesh out` vs `full-fledged`.
      FleshOutVsFullFledged = true;
      #> Corrects `foam out the mouth` → `foam at the mouth`.
      FoamAtTheMouth = true;
      #> Flags `fond on` → `found on`/`fond of`.
      FondOn = true;
      #> Corrects `'` and `"` for measurements to prime/double-prime.
      FootInchMinuteSecondSymbols = true;
      #> Corrects `flip the bill` → `foot the bill`.
      FootTheBill = true;
      #> Eliminates incorrect `for along time`.
      ForALongTime = true;
      #> Corrects `for argument sake` → `for argument's sake`.
      ForArgumentsSake = true;
      #> Corrects `for while` → `for a while`.
      ForAWhile = true;
      #> Corrects `for free of charge`.
      ForFreeOfCharge = true;
      #> Corrects `formidable years` → `formative years`.
      FormativeYears = true;
      #> Corrects archaic `fro` → `for` before nouns.
      ForNoun = true;
      #> Detects `reason` vs `reasons` misuse.
      ForSameReason = true;
      #> Corrects `for most part` → `for the most part`.
      ForTheMostPart = true;
      #> Adds missing `the` for nth occurrences.
      ForTheNthTime = true;
      #> Expands initialism `FWIW`.
      ForWhatItsWorth = true;
      #> Expands initialism `FYI`.
      ForYourInformation = true;
      #> Swaps `fee` → `free` after a linking verb.
      FreePredicate = true;
      #> Ensures `free rein` (not `free reign`).
      FreeRein = true;
      #> Suggests `freezing` for `very cold`.
      Freezing = true;
      #> Corrects `a friend of me` → `a friend of mine`.
      FriendOfMe = true;
      #> Hyphenates `from the get-go`.
      FromTheGetGo = true;
      #> Corrects wrong preposition `full to the brim`.
      FullToTheBrim = true;
      #> Fixes spacing inside `furthermore`.
      Furthermore = true;
      #> Corrects `pass` → `past` after `get`/`go`.
      GetPassGoPass = true;
      #> Corrects misspellings of `get rid of`.
      GetRidOf = true;
      #> Corrects `used of` → `used to`.
      GetUsedTo = true;
      #> Uses `Gilded Age` for the period.
      GildedAge = true;
      #> Corrects `goggle` in Google product context.
      GoggleBrand = true;
      #> Corrects `gong to` → `going to`.
      GoingTo = true;
      #> Corrects `become missing` → `go missing`.
      GoMissing = true;
      #> Corrects `good in` → `good at` for proficiency.
      GoodAt = true;
      #> Google product names must be proper nouns.
      GoogleNames = true;
      #> Flags `go so far to` → `go so far as to`.
      GoSoFarAsTo = true;
      #> Corrects `go into sleep` → `go to sleep`.
      GoToSleep = true;
      #> Replaces `go at war` → `go to war`.
      GoToWar = true;
      #> Corrects `grind to halt` → `grind to a halt`.
      GrindToAHalt = true;
      #> Fixes spacing inside `guesswork`.
      Guesswork = true;
      #> Corrects `Guinea-Bissau`.
      GuineaBissau = true;
      #> Flags unnecessary `of` after `had`.
      HadOf = true;
      #> Fixes `half an our` → `half an hour`.
      HalfAnHour = true;
      #> Corrects `hallucinization`.
      Hallucination = true;
      #> Keeps `handful` as one word.
      Handful = true;
      #> Removes nonstandard `of` from `handful of more`.
      HandfulOfMore = true;
      #> Corrects `half hazard` → `haphazard`.
      Haphazard = true;
      #> Corrects `have hard time` → `have a hard time`.
      HaveAHardTime = true;
      #> Rewrites `no` → `any` in `haven't done no X`.
      HaveNegNoAny = true;
      #> Suggests `past` for `passed` after `have`.
      HavePassed = true;
      #> Flags `has we`/`has I` → `have`.
      HavePronoun = true;
      #> Corrects `have a look` vs `take a look` by dialect.
      HaveTakeALook = true;
      #> Hazzle collection.
      Hazzle = true;
      #> Corrects `heart`/`herd` → `heard`.
      HeartToHeard = true;
      #> Flags hedging language.
      Hedging = true;
      #> Corrects `dos` → `does` after he/she/it.
      HeDos = true;
      #> Prefers `hello` for greeting (not `halo`).
      HelloGreeting = true;
      #> Base form of verbs after `helped`.
      HelpedPast = true;
      #> Fixes spacing inside `henceforth`.
      Henceforth = true;
      #> Corrects `here by` → `hereby`.
      Hereby = true;
      #> Corrects `hidden into` → `hidden in`.
      HiddenIn = true;
      #> Corrects `high/low standard` → `standards`.
      HighLowStandards = true;
      #> Corrects misspellings of `hijack`.
      Hijack = true;
      #> Corrects `hit the nail in the head` → `on the head`.
      HitTheNailOnTheHead = true;
      #> Holiday names must be proper nouns.
      Holidays = true;
      #> Corrects misspellings of `holy war`.
      HolyWar = true;
      #> Corrects `hone in on` → `home in on`.
      HomeInOn = true;
      #> Handles `hop`/`hope` errors.
      HopHope = true;
      #> Corrects `how do/does compared`.
      HowDoesCompared = true;
      #> Fixes spacing inside `however`.
      However = true;
      #> Corrects `how ... looks like`.
      HowItLooksLike = true;
      #> Corrects `how mach`/`how match` → `how much`.
      HowMach = true;
      #> Detects missing `to` in `how clone` → `how to …`.
      HowTo = true;
      #> Eliminates `human's beings`/`humans beings`.
      HumanBeings = true;
      #> Corrects `human live` → `human life`.
      HumanLife = true;
      #> Corrects `hunger pain` → `hunger pang`.
      HungerPang = true;
      #> Hyphenates `4-day` compound adjectives.
      HyphenateNumberDay = true;
      #> Fixes `I a m` → `I am`.
      IAm = true;
      #> Corrects `I are` → `I am`.
      IAmAgreement = true;
      #> Corrects `I does` → `I do`.
      IDo = true;
      #> Expands initialism `IDK`.
      IDontKnow = true;
      #> Expands initialism `IIRC`.
      IfIRecallCorrectly = true;
      #> Expands initialism `IICU`.
      IfIUnderstandCorrectly = true;
      #> Corrects `if I would've done` → `if I had done`.
      IfWouldve = true;
      #> Expands initialism `IYKYK`.
      IfYouKnowYouKnow = true;
      #> After `imitate ...`, prefer `of`.
      ImitateFrom = true;
      #> Corrects `implement into` → `implement in`.
      ImplementIn = true;
      #> Corrects `impressed of` → `impressed by`/`with`.
      Impressed = true;
      #> Corrects `into` → `in` for direction/strategy changes.
      InADifferentDirection = true;
      #> Corrects `in hurry` → `in a hurry`.
      InAHurry = true;
      #> Corrects `in ideal world` → `in an ideal world`.
      InAnIdealWorld = true;
      #> Corrects ungrammatical `in anyway` → `in any way`.
      InAnyWay = true;
      #> Corrects `in while` → `in a while`.
      InAWhile = true;
      #> Expands initialism `ICYMI`.
      InCaseYouMissedIt = true;
      #> Incident report collection.
      IncidentReport = true;
      #> Adds commas around `including, but not limited to,`.
      IncludingButNotLimitedToPunctuation = true;
      #> Hyphenates `in-demand` / `in-depth` as adjectives.
      InDemandInDepth = true;
      #> Corrects `in details` → `in detail`.
      InDetail = true;
      #> Corrects `in do course` → `in due course`.
      InDueCourse = true;
      #> Adds missing `of` in `in favour of doing`.
      InFavourOfDoing = true;
      #> Flags non-infinitive verb after `to`.
      InflectedVerbAfterTo = true;
      #> Corrects `infliction point` → `inflection point`.
      InflectionPoint = true;
      #> Corrects `in hindsight` variants.
      InHindsight = true;
      #> Corrects nonstandard `initiatively`.
      Initiatively = true;
      #> Corrects `in lue of` → `in lieu of`.
      InLieuOf = true;
      #> Expands initialism `IMHO`.
      InMyHumbleOpinion = true;
      #> Expands initialism `IMO`.
      InMyOpinion = true;
      #> Corrects `in need for` → `in need of`.
      InNeedOf = true;
      #> In-of-itself collection.
      InOfItself = true;
      #> Corrects `to my defense` → `in my defense`.
      InOnesDefense = true;
      #> Corrects `in/on the cards` by dialect.
      InOnTheCards = true;
      #> Expands initialism `IRL`.
      InRealLife = true;
      #> Corrects `in retaliation to`.
      InRetaliationTo = true;
      #> Suggests `insensitive` (more common).
      Insensitive = true;
      #> Fixes spacing inside `insofar`.
      Insofar = true;
      #> Corrects `inspired from` → `inspired by`.
      InspiredBy = true;
      #> Fixes spacing inside `instead`.
      Instead = true;
      #> Corrects `in stead of` → `instead of`.
      InsteadOf = true;
      #> Corrects `on stock` → `in stock`.
      InStock = true;
      #> Suggests `insurmountable` (more common).
      Insurmountable = true;
      #> Fixes spacing inside `intact`.
      Intact = true;
      #> Ensures `interested in`.
      InterestedIn = true;
      #> Corrects `int he` → `in the`.
      InThe = true;
      #> Corrects `at the first place` → `in the first place`.
      InTheFirstPlace = true;
      #> Corrects `in the grand scheme of things` variants.
      InTheGrandSchemeOfThings = true;
      #> Corrects `in the same vein` variants.
      InTheSameVein = true;
      #> Corrects `in this/that regards` → `regard`.
      InThisThatRegard = true;
      #> Removes redundant `in` before `[period] from now`.
      InTimeFromNow = true;
      #> Adds missing comma in `No thanks`.
      IntroCueCommaBeforeThanks = true;
      #> `Invest` pairs with `in`.
      InvestIn = true;
      #> Rewrites `is been` to standard perfect-passive.
      IsBeenAuxSequence = true;
      #> `known` is the past participle.
      IsKnownFor = true;
      #> Corrects `It cam` → `It can`.
      ItCan = true;
      #> Corrects `it looks like that` → `it looks like`.
      ItLooksLikeThat = true;
      #> Distinguishes `its` from `it's` before verbs/clauses.
      ItsContraction = true;
      #> Fixes spacing inside `itself`.
      Itself = true;
      #> `its` (possessive) never takes an apostrophe.
      ItsPossessive = true;
      #> Adds `'s` in `it time to/for`.
      ItTimeAuxiliary = true;
      #> Corrects `I've go to` → `I've got to`.
      IveGotTo = true;
      #> Corrects `jar-dropping` → `jaw-dropping`.
      JawDropping = true;
      #> Prefers `jealous of`.
      JealousOf = true;
      #> Jetpack product names must be proper nouns.
      JetpackNames = true;
      #> Recommends `Johns Hopkins`.
      JohnsHopkins = true;
      #> Detects `jump the gun` misuse.
      JumpTheGun = true;
      #> Ensures `just deserts`.
      JustDeserts = true;
      #> Fixes spacing inside `keystroke`.
      Keystroke = true;
      #> Fixes spacing inside `keystrokes`.
      Keystrokes = true;
      #> Corrects `kinda of` → `kind of`.
      KindOf = true;
      #> Corrects `kid regards` → `kind regards`.
      KindRegards = true;
      #> Fixes `kind if`/`sort off` before qualifiers.
      KindSortOf = true;
      #> Corrects `no nothing` → `know nothing`.
      KnowNothingVerb = true;
      #> Korea names must be proper nouns.
      Koreas = true;
      #> Laos names must be proper nouns.
      Laos = true;
      #> Fixes spacing inside `laptop`.
      Laptop = true;
      #> Corrects `last but not least` variants.
      LastButNotLeast = true;
      #> Corrects `last-ditch` variants.
      LastDitch = true;
      #> Flags `yesterday night` → `last night`.
      LastNight = true;
      #> Nudges `laugh of` → `laugh at`.
      LaughOfAt = true;
      #> Flags nonstandard `layout` verb forms.
      LayoutVerb = true;
      #> Corrects `leads rise to` → `gives rise to`.
      LeadRiseTo = true;
      #> Prefers `leave for a destination`.
      LeaveToFor = true;
      #> Corrects `leaving in drones` → `leaving in droves`.
      LeavingInDroves = true;
      #> Hyphenates `left-hand`/`right-hand` as adjectives.
      LeftRightHand = true;
      #> Suggests alternatives to `less worse`/`least worst`.
      LessWorse = true;
      #> Corrects `let along` → `let alone`.
      LetAlone = true;
      #> Expands initialism `LMK`.
      LetMeKnow = true;
      #> Handles `let` errors.
      LetsConfusion = true;
      #> Corrects extraneous `to` after `let`.
      LetToDo = true;
      #> Corrects `level of details`.
      LevelOfDetails = true;
      #> Fixes spacing inside `lifetime`.
      Lifetime = true;
      #> Corrects `like as if`.
      LikeAsIf = true;
      #> Joins `likely hood` → `likelihood`.
      LikelyHood = true;
      #> Corrects `like a plague` → `like the plague`.
      LikeThePlague = true;
      #> Corrects `like no tomorrow` → `like there's no tomorrow`.
      LikeTheresNoTomorrow = true;
      #> Fixes spacing inside `likewise`.
      Likewise = true;
      #> Corrects `line of codes` → `lines of code`.
      LinesOfCode = true;
      #> Linked-list collection.
      LinkedList = true;
      #> Suggests direct positives for litotes.
      LitotesDirectPositive = true;
      #> Fixes `little known`.
      LittleKnown = true;
      #> Flags overly long sentences.
      LongSentences = true;
      #> Adds `a` before `long time ago`.
      LongTimeAgo = true;
      #> Corrects `look-a-like`.
      Lookalike = true;
      #> Corrects `look one's nose down`.
      LookDownOnesNose = true;
      #> Corrects `look forward for` → `look forward to`.
      LookForwardTo = true;
      #> Requires gerund after `looking forward to`.
      LookingForwardTo = true;
      #> Joins `look into` before clauses.
      LookInto = true;
      #> Corrects `looks likes` → `look ... like`.
      LooksLikes = true;
      #> Lots collection.
      Lots = true;
      #> Corrects `low-hanging fruit` variants.
      LowHangingFruit = true;
      #> Corrects `make due with` → `make do with`.
      MakeDoWith = true;
      #> Corrects `make it seems` → `make it seem`.
      MakeItSeem = true;
      #> Corrects `make senses` → `make sense`.
      MakeSense = true;
      #> Joins `makeup` as compound noun.
      MakeupCompoundNoun = true;
      #> Malaysia names must be proper nouns.
      Malaysia = true;
      #> Corrects `managerial reigns` → `reins`.
      ManagerialReins = true;
      #> Corrects `max exodues` → `mass exodus`.
      MassExodus = true;
      #> Detects count usage of mass nouns.
      MassNouns = true;
      #> May + pronoun construction.
      MayOfPronoun = true;
      #> Corrects `means a lot for` → `means a lot to`.
      MeansALotTo = true;
      #> Fixes spacing inside `meanwhile`.
      Meanwhile = true;
      #> `Mercedes-Benz` hyphenation.
      MercedesBenzHyphen = true;
      #> Joins split words accidentally separated.
      MergeWords = true;
      #> Meta product names must be proper nouns.
      MetaNames = true;
      #> Microsoft product names must be proper nouns.
      MicrosoftNames = true;
      #> Fixes spacing inside `middleware`.
      Middleware = true;
      #> Flags missing determiners.
      MissingDeterminer = true;
      #> Flags missing prepositions.
      MissingPreposition = true;
      #> Adds missing `to` before infinitives.
      MissingTo = true;
      #> Ensures `misspell` is one word.
      Misspell = true;
      #> Fixes spacing inside `misunderstand`.
      Misunderstand = true;
      #> Fixes spacing inside `misunderstood`.
      Misunderstood = true;
      #> Fixes spacing inside `misuse`.
      Misuse = true;
      #> Fixes spacing inside `misused`.
      Misused = true;
      #> Corrects `mixed bad` → `mixed bag`.
      MixedBag = true;
      #> Flags missing `be` between modal and adjective.
      ModalBeAdjective = true;
      #> Detects `of` misused with modals.
      ModalOf = true;
      #> Detects `seen` → `seem`/`be` after modals.
      ModalSeem = true;
      #> Capitalises month names.
      Months = true;
      #> Advises `momentous`/`monumental`.
      Monumentous = true;
      #> Corrects `mute point` → `moot point`.
      MootPoint = true;
      #> Suggests inflected forms over `more + adjective`.
      #! default: false
      MoreAdjective = false;
      #> Flags redundant `more better` / `most best`.
      MoreBetter = true;
      #> Corrects `more than meets the eye` variants.
      MoreThanMeetsTheEye = true;
      #> Corrects `more that likely` → `more than likely`.
      MoreThatLikely = true;
      #> Corrects `most number` / `most amount`.
      MostNumber = true;
      #> Corrects `most of the times` → `most of the time`.
      MostOfTheTimes = true;
      #> Fixes spacing inside `multicore`.
      Multicore = true;
      #> Fixes spacing inside `multimedia`.
      Multimedia = true;
      #> Flags adjacent frequency adverbs.
      MultipleFrequencyAdverbs = true;
      #> Flags multiple sequential disparate pronouns.
      MultipleSequentialPronouns = true;
      #> Fixes spacing inside `multithreading`.
      Multithreading = true;
      #> Fixes typo `mu house` → `my house`.
      MyHouse = true;
      #> Fixes spacing inside `myself`.
      Myself = true;
      #> Corrects `nail on the coffin` → `nail in the coffin`.
      NailInCoffin = true;
      #> Corrects `nail on the head` variants.
      NailOnTheHead = true;
      #> Corrects wrong prepositions for `naked eye`.
      NakedEye = true;
      #> National capital names must be proper nouns.
      NationalCapitals = true;
      #> Corrects `ned help` → `need help`.
      NeedHelp = true;
      #> Flags `need to` + noun (missing verb).
      NeedToNoun = true;
      #> Neither-here-nor-there collection.
      NeitherHereNorThere = true;
      #> Corrects `nerve-racking` misspellings.
      NerveRacking = true;
      #> Suggests `nervous wreck`.
      NervousWreck = true;
      #> Expands initialism `NVM`.
      NeverMind = true;
      #> Corrects `Nobel Peace Prize` spelling.
      NobelPeacePrize = true;
      #> Fixes spacing inside `nobody`.
      Nobody = true;
      #> Blocks accidental French spaces.
      NoFrenchSpaces = true;
      #> Corrects `no harm, no foul` variants.
      NoHarmNoFoul = true;
      #> Corrects `not longer` → `no longer`.
      NoLonger = true;
      #> Detects `no longer` + subject pronoun.
      NoLongerPronoun = true;
      #> "No match for" idiom.
      NoMatchFor = true;
      #> Ensures `want`/`wants` after a nominal.
      NominalWants = true;
      #> Fixes spacing inside `nonetheless`.
      Nonetheless = true;
      #> Flags absence of Oxford comma in lists.
      #! default: false
      NoOxfordComma = false;
      #> Corrects pronoun/modal order after `nor`.
      NorModalPronoun = true;
      #> Notable place names must be proper nouns.
      NotablePlaces = true;
      #> Removes redundant `be` after `not`.
      NotBeAfterNot = true;
      #> Rewrites `not without a lack of` → `not for lack of`.
      NotForLackOf = true;
      #> Fixes spacing inside `nothing`.
      Nothing = true;
      #> Replaces `no in` → `not in`.
      NotIn = true;
      #> Not-long-after collection.
      NotLongAfter = true;
      #> Corrects `no only` → `not only` before `to be`.
      NotOnly = true;
      #> Corrects `not only it is` → `not only is it`.
      NotOnlyInversion = true;
      #> Corrects `no to` → `not to`.
      NotTo = true;
      #> Fixes spacing inside `notwithstanding`.
      Notwithstanding = true;
      #> Handles noun/verb confusions (`advice`/`advise`).
      NounVerbConfusion = true;
      #> Corrects `nowadays` misspellings.
      Nowadays = true;
      #> Fixes spacing inside `nowhere`.
      Nowhere = true;
      #> Corrects `now know as` → `now known as`.
      NowKnownAs = true;
      #> Corrects `now way` → `no way`.
      NowWay = true;
      #> Number suffixes are never capitalised.
      NumberSuffixCapitalization = true;
      #> Replaces hyphens and em dashes with en dashes in isolated numeric ranges such as `12–14`.
      NumericRangeEnDash = false; #! overridden
      #> Ensures valid prepositions with `obsess`.
      ObsessPreposition = true;
      #> Oceans and seas must be proper nouns.
      OceansAndSeas = true;
      #> Corrects `of course` variants (`of curse`, `off course`).
      OfCourse = true;
      #> Corrects `off-limit` → `off-limits`.
      OffLimits = true;
      #> Hyphenates `off-the-cuff`.
      OffTheCuff = true;
      #> Fixes spacing inside `oftentimes`.
      Oftentimes = true;
      #> Expands initialism `OMG`.
      OhMyGod = true;
      #> Corrects `ok` → `okay`.
      OkToOkay = true;
      #> Detects `oldest in the books` → `book`.
      OldestInTheBook = true;
      #> Corrects `old wise tale` → `old wives' tale`.
      OldWivesTale = true;
      #> On-a-daily-basis collection.
      OnADailyBasis = true;
      #> Corrects `once in a while` malapropisms.
      OnceInAWhile = true;
      #> Corrects `once a twice` → `once or twice`.
      OnceOrTwice = true;
      #> Flags `one in the same` → `one and the same`.
      OneAndTheSame = true;
      #> Corrects `one foul swoop` → `one fell swoop`.
      OneFellSwoop = true;
      #> Joins `one handed` / `two handed`.
      OneHanded = true;
      #> Corrects `one of the [singular]` → plural.
      OneOfTheSingular = true;
      #> Corrects `on one's own accord` → `of one's own accord`.
      OnesOwnAccord = true;
      #> Corrects `one's self` → `oneself`.
      OnesSelf = true;
      #> Prefers `at first glance`.
      OnFirstGlance = true;
      #> Corrects `in/at the floor` → `on the floor`.
      OnFloor = true;
      #> Corrects `on second though` → `on second thought`.
      OnSecondThought = true;
      #> Corrects `on a fence` → `on the fence`.
      OnTheFence = true;
      #> Expands initialism `OTOH`.
      OnTheOtherHand = true;
      #> Ensures `on the spur of the moment`.
      OnTheSpurOfTheMoment = true;
      #> Corrects `ontop of`/`in top of` → `on top of`.
      OnTopOf = true;
      #> Corrects compound words split by spaces.
      OpenCompounds = true;
      #> Corrects `open the light` → `turn on`/`switch on`.
      OpenTheLight = true;
      #> Ensures `operating system`.
      OperatingSystem = true;
      #> Matches canonical orthography casing.
      OrthographicConsistency = true;
      #> Detects `out to be` → `ought to be`.
      OughtToBe = true;
      #> Hyphenates `out-of-date` as adjective.
      OutOfDate = true;
      #> Corrects `out of sink` → `out of sync`.
      OutOfSync = true;
      #> Expands initialism `OOTB`.
      OutOfTheBox = true;
      #> `out (of) the window` idiom.
      OutOfTheWindow = true;
      #> Fixes spacing inside `overall`.
      Overall = true;
      #> Fixes spacing inside `overclocking`.
      Overclocking = true;
      #> Fixes spacing inside `overload`.
      Overload = true;
      #> Fixes spacing inside `overnight`.
      Overnight = true;
      #> Detects redundant `over` + `plus` with numbers.
      OverPlus = true;
      #> Joins `overtime` as compound noun in job-hours contexts.
      OvertimeCompoundNoun = true;
      #> The Oxford comma is one of the more controversial rules in common use today. Enabling this lint checks that there is a comma before `and`, `or`, or `nor` when listing out more than two ideas.
      OxfordComma = false; #! overridden
      #> Flags oxymoronic phrases.
      Oxymorons = true;
      #> Corrects `pale by comparison` variants.
      PaleByComparison = true;
      #> Corrects `part of speeches` → `parts of speech`.
      PartsOfSpeech = true;
      #> Corrects `passerbys` → `passersby`.
      PassersBy = true;
      #> Corrects `passtionate of` → `passionate about`.
      PassionateAbout = true;
      #> Hyphenates `password-protected`.
      PasswordProtectedHyphen = true;
      #> Corrects `payed` → `paid`.
      Payed = true;
      #> Corrects extraneous `for` in price/fee contexts.
      PayForPrice = true;
      #> Corrects `piece of mind` → `peace of mind`.
      PeaceOfMind = true;
      #> Corrects `pedal to the medal` → `pedal to the metal`.
      PedalToTheMetal = true;
      #> Corrects `peak behind the curtain` → `peek`.
      PeekBehindTheCurtain = true;
      #> Corrects `per se` misspellings.
      PerSe = true;
      #> Flags phrasal verbs used as compound nouns.
      PhrasalVerbAsCompoundNoun = true;
      #> Corrects `piggy bag` → `piggyback`.
      Piggyback = true;
      #> Corrects `peak`/`peek` → `pique` in `pique interest`.
      PiqueInterest = true;
      #> Corrects `play a factor`.
      PlayAFactor = true;
      #> Expands initialism `PTAL`.
      PleaseTakeALook = true;
      #> Fixes typo `pleas` → `please` before request verbs.
      PleasRequestVerb = true;
      #> Flags `'90s`-style apostrophe in decades.
      PluralDecades = true;
      #> Corrects pluralising the wrong noun in phrases.
      PluralWrongWordOfPhrase = true;
      #> Pocket Casts name must be proper noun.
      PocketCastsNames = true;
      #> Corrects `point of views` → `points of view`.
      PointsOfView = true;
      #> Checks `Port-au-Prince` spelling.
      PortAuPrince = true;
      #> Checks `Porto-Novo` spelling.
      PortoNovo = true;
      #> Apostrophe + `s` for possessive nouns.
      #! default: false
      PossessiveNoun = false;
      #> `your` before nouns (possessive).
      PossessiveYour = true;
      #> Joins `post-it note` → `Post-it`.
      PostItNoteHyphen = true;
      #> Fixes spacing inside `postpone`.
      Postpone = true;
      #> Corrects `preying mantis` → `praying mantis`.
      PrayingMantis = true;
      #> Prefers `pleaded` over `pled`.
      PreferPleaded = true;
      #> Prefers `pled` over `pleaded`.
      #! default: false
      PreferPled = false;
      #> Prefers `sneaked` over `snuck`.
      PreferSneaked = true;
      #> Prefers `snuck` over `sneaked`.
      #! default: false
      PreferSnuck = false;
      #> Corrects `principle` → `principal` before role nouns.
      PrincipleToPrincipalRoleNoun = true;
      #> Detects `<pronoun> have ...ing` errors.
      ProgressiveNeedsBe = true;
      #> Spots `r` for `are`/`you're` after pronouns.
      PronounAre = true;
      #> Handles pronoun-contraction errors.
      PronounContraction = true;
      #> Subject-verb agreement for `be`.
      PronounInflectionBe = true;
      #> Detects `new` (typo for `knew`) after pronouns.
      PronounKnew = true;
      #> Ensures pronouns agree with verbs.
      PronounVerbAgreement = true;
      #> Fixes spacing inside `proofread`.
      Proofread = true;
      #> Capitalises proper nouns.
      ProperNouns = true;
      #> Corrects `provocate` → `provoke`.
      Provocate = true;
      #> Adds missing `of` after `a couple`.
      QuantifierNeedsOf = true;
      #> Detects quantifier-numeral conflicts.
      QuantifierNumeralConflict = true;
      #> Corrects `quite many` → `quite a few`.
      QuiteMany = true;
      #> Distinguishes `quiet` from `quite`.
      QuiteQuiet = true;
      #> Checks quote mark spacing.
      QuoteSpacing = true;
      #> Hyphenates `rainbow-colored` before nouns.
      RainbowColoredHyphen = true;
      #> Corrects `rally` → `really` in `be ...ing` constructions.
      RallyToReally = true;
      #> Hyphenates `rapid-fire`.
      RapidFire = true;
      #> Ensures `read`/`write` forms are consistent.
      ReadsAndWrites = true;
      #> Expands `really` (collection).
      Really = true;
      #> Ensures `real trouper` (not `trooper`).
      RealTrouper = true;
      #> Corrects `reason of doing` → `reason for doing`.
      ReasonForDoing = true;
      #> Flags redundant acronyms (`ATM machine`).
      RedundantAcronyms = true;
      #> Detects redundant additive adverbs.
      RedundantAdditiveAdverbs = true;
      #> Detects `almost` + `nearly` together.
      RedundantAlmostNearly = true;
      #> Flags redundant `first` with order-implying verbs.
      RedundantFirsts = true;
      #> Flags redundant `if`/`correctly` with `IIRC`.
      RedundantIIRC = true;
      #> `Pretty decent` → `decent`.
      RedundantPretty = true;
      #> Detects `increasingly more/less`.
      RedundantProgressiveComparative = true;
      #> Detects redundant `self-` with reflexive pronouns.
      RedundantSelf = true;
      #> Simplifies `most optimal` → `optimal`.
      RedundantSuperlatives = true;
      #> Collapses `that that` → `that`.
      RedundantThat = true;
      #> Fixes spacing inside `regardless`.
      Regardless = true;
      #> Distinguishes `regimen` (routine) from `regiment`.
      RegimenRegiment = true;
      #> Flags regionalisms.
      Regionalisms = true;
      #> Replaces regular inflections of irregular words.
      RegularIrregulars = true;
      #> Corrects `relay on` → `rely on`.
      RelayOnForRely = true;
      #> Flags non-homograph repeated words.
      RepeatedWords = true;
      #> Flags noun `response` where verb `respond` fits.
      Respond = true;
      #> Corrects `responsibility of` → `responsibility for`.
      ResponsibilityFor = true;
      #> Corrects `responsible about` → `responsible for`.
      ResponsibleFor = true;
      #> Corrects `reversed engineer` → `reverse engineer`.
      ReverseEngineer = true;
      #> Corrects `ripe with` → `rife with`.
      RifeWith = true;
      #> Hyphenates `right-click`.
      RightClick = true;
      #> Corrects `rise the question` → `raise the question`.
      RiseTheQuestion = true;
      #> Corrects `rise the ranks` variants.
      RiseTheRanks = true;
      #> Distinguishes `roadmap` from `road map`.
      RoadMap = true;
      #> Distinguishes `rogue` from `rouge`.
      RogueRouge = true;
      #> Hyphenates `roller-skated`.
      RollerSkated = true;
      #> Corrects `rule of thumbs` → `rules of thumb`.
      RulesOfThumb = true;
      #> Corrects `run into problems`/`trouble` variants.
      RunIntoProblemsOrTrouble = true;
      #> Distinguishes `safe` from `save` after modals.
      SafeToSave = true;
      #> Corrects `same then` → `same as`.
      SameAs = true;
      #> Corrects `save to <verb>` → `safe to <verb>`.
      SaveToSafe = true;
      #> Fixes `scandally clad` → `scantily clad`.
      ScantilyClad = true;
      #> Corrects `scape goat` → `scapegoat`.
      ScapeGoat = true;
      #> Corrects `seam` → `seem` (verb).
      SeamToSeem = true;
      #> Corrects `seize control over` → `of`.
      SeizeControlOf = true;
      #> Replaces `send an email to` → `email`.
      SendAnEmailTo = true;
      #> The opening word of a sentence should almost always be capitalized.
      SentenceCapitalization = false; #! overridden
      #> Corrects `set up a bad example` → `set a bad example`.
      SetABadExample = true;
      #> Corrects `shoot oneself in the foot` variants.
      ShootOneselfInTheFoot = true;
      #> Fixes spacing inside `shortcoming`.
      Shortcoming = true;
      #> Fixes spacing inside `shortcomings`.
      Shortcomings = true;
      #> Corrects `show case` → `showcase`.
      ShowCase = true;
      #> Keeps `shutdown` noun vs `shut down` verb.
      ShutdownVerb = true;
      #> Corrects redundant `side tangent`.
      SideTangent = true;
      #> Pairs `similar` with `to`.
      SimilarLike = true;
      #> Corrects `simply grammatical` → `simple grammatical`.
      SimpleGrammatical = true;
      #> Uses past participle after auxiliaries.
      SimplePastToPastParticiple = true;
      #> Detects `since` with a duration.
      SinceDuration = true;
      #> Removes duplicate `be` inflections.
      SingleBe = true;
      #> Fixes spacing inside `skyrocket`.
      Skyrocket = true;
      #> Corrects `slippy slope` → `slippery slope`.
      SlipperySlope = true;
      #> Changes `sneaky suspicion` → `sneaking suspicion`.
      SneakingSuspicion = true;
      #> Corrects `sneak peak` → `sneak peek`.
      SneakPeekPreview = true;
      #> Fixes spacing inside `somebody`.
      Somebody = true;
      #> Corrects `somebody else's` positioning.
      SomebodyElses = true;
      #> Fixes spacing inside `somehow`.
      Somehow = true;
      #> Prefers `some of the` before definite articles.
      SomeOfThe = true;
      #> Fixes spacing inside `someone`.
      Someone = true;
      #> Corrects `somethings` → `something's`/`something is`.
      SomethingIs = true;
      #> Prefers `something of a` over `somewhat of a`.
      SomewhatSomething = true;
      #> Fixes spacing inside `somewhere`.
      Somewhere = true;
      #> Flags redundant article before `some`.
      SomeWithoutArticle = true;
      #> Corrects `sooner than later` variants.
      SoonerOrLater = true;
      #> Hyphenates `soon-to-be` before nouns.
      SoonToBe = true;
      #> Corrects `sort after` → `sought after`.
      SoughtAfter = true;
      #> Collapses double spaces.
      Spaces = true;
      #> Changes `spacial attention` → `special attention`.
      SpecialAttention = true;
      #> Spell checker.
      SpellCheck = true;
      #> Prefers numbers < 10 spelled out.
      #! default: false
      SpelledNumbers = false;
      #> Corrects `spinal chord` → `spinal cord`.
      SpinalChord = true;
      #> Joins split compound words.
      SplitWords = true;
      #> Suggests `starving` for `very hungry`.
      Starving = true;
      #> Corrects `state of art` → `state of the art`.
      StateOfTheArt = true;
      #> Corrects `statue of limitations` → `statute of limitations`.
      StatuteOfLimitations = true;
      #> Fixes spacing inside `straightforward`.
      Straightforward = true;
      #> Fixes `strike a cord` → `strike a chord`.
      StrikeChord = true;
      #> Corrects `strike of genius` → `stroke of genius`.
      StrikeOfGenius = true;
      #> Corrects `strike of luck` → `stroke of luck`.
      StrikeOfLuck = true;
      #> Prefers `subject`/`object pronoun`.
      SubjectAndObjectPronoun = true;
      #> Corrects `me and X` → `X and I`.
      SubjectPronoun = true;
      #> Uses subjunctive `were` in counterfactuals.
      SubjunctiveWasToWere = true;
      #> Corrects `such shame` → `such a shame`.
      SuchShame = true;
      #> Corrects `suffice to say` → `suffice it to say`.
      SufficeItToSay = true;
      #> Distinguishes `summary` from `summery`.
      SummarySummery = true;
      #> Corrects `suppose to` → `supposed to`.
      SupposedTo = true;
      #> Suggests `surreality` for `surrealness`.
      Surreality = true;
      #> Corrects `take a look to` → `take a look at`.
      TakeALookTo = true;
      #> Corrects `take care about` → `take care of`.
      TakeCareOf = true;
      #> Corrects `take control over` → `take control of`.
      TakeControlOf = true;
      #> Corrects `take it personal` → `take it personally`.
      TakeItPersonally = true;
      #> Prefers `take`/`swallow` for medicine (not `eat`).
      TakeMedicine = true;
      #> Corrects `take pride of` → `take pride in`.
      TakePrideIn = true;
      #> Expands initialism `TTYL`.
      TalkToYouLater = true;
      #> Fixes spacing inside `tenfold`.
      Tenfold = true;
      #> Adds missing `a` before `thanks lot`.
      ThanksALot = true;
      #> Corrects `the challenged` → `that challenged`.
      ThatChallenged = true;
      #> Corrects `that` → `than` in comparisons.
      ThatThan = true;
      #> Fixes `the this` → `that this`.
      ThatThis = true;
      #> Prefers `that which`.
      ThatWhich = true;
      #> Fixes common `the` misspellings.
      The = true;
      #> Corrects `the another`.
      TheAnother = true;
      #> Corrects `the different(s) between` → `the difference between`.
      TheDifferenceBetween = true;
      #> Corrects `the entire of` → `the entirety of`.
      TheEntiretyOf = true;
      #> Removes extra `the` in `the how`/`the why`.
      TheHowWhy = true;
      #> Corrects `their` → `there`.
      TheirToThere = true;

      #> Corrects `in the last days` → `in the last few days`.
      TheLastDays = true;
      #> Corrects `their self` → `themself`/`themselves`.
      Themself = true;
      #> Flags `the` + possessive determiner.
      TheMy = true;
      #> Distinguishes `then` from `than`.
      ThenThan = true;
      #> Corrects `the point for` → `the point of`.
      ThePointFor = true;
      #> Flags redundant `the` + possessive proper noun.
      TheProperNounPossessive = true;
      #> Fixes spacing inside `there`.
      There = true;
      #> Joins `there after` → `thereafter`.
      ThereAfterCompound = true;
      #> Fixes spacing inside `therefore`.
      Therefore = true;
      #> Flags `there in`/`there-in` → `therein`.
      Therein = true;
      #> Subject-verb agreement in `there is`.
      ThereIsAgreement = true;
      #> Inserts `is` in `if there a ...`.
      ThereMissingIsClause = true;
      #> Corrects `there own`/`they're own` → `their own`.
      ThereOwn = true;
      #> Replaces `their's` → `there's`.
      Theres = true;
      #> Corrects `there` → `their`.
      ThereToTheir = true;
      #> Fixes spacing inside `thereupon`.
      Thereupon = true;
      #> Corrects `theses` → `these`.
      ThesesThese = true;
      #> Corrects `the the` → `that the` or `the`.
      TheTheToThatThe = true;
      #> Fixes `the whether` → `the weather`.
      TheWhetherWeather = true;
      #> Handles `they're` confusions.
      TheyreConfusions = true;

      #> Converts `they` → `them` as object.
      TheyToThem = true;
      #> Fixes `thieve` → `thief` in noun phrases.
      ThieveNoun = true;
      #> Corrects `thing` → `think`.
      ThingThink = true;
      #> Fixes `know off`/`thought off` → `of`.
      ThinkKnowOff = true;
      #> Ensures number agreement in `this/these type(s) of thing(s)`.
      ThisTypeOfThing = true;
      #> Corrects `though` → `thought`.
      ThoughThought = true;
      #> Changes `though process` → `thought process`.
      ThoughtProcess = true;
      #> Normalises `threat` → `threaten` after modals.
      ThreatenVerb = true;
      #> Corrects `thrive off` → `thrive on`.
      ThriveOn = true;
      #> Fixes `through away` → `throw away`/`threw away`.
      ThrowAway = true;
      #> Corrects `throw the baby out with the bathwater` variants.
      ThrowBabyWithBathwater = true;
      #> Checks `throw rubbish` → `throw away`.
      ThrowRubbish = true;
      #> Corrects `ticking time clock` → `ticking time bomb`/`ticking clock`.
      TickingTimeClock = true;
      #> Corrects Indian English `till date` → `to date` (non-IN dialect).
      TillDate = true;
      #> Flags duplicated `to` around adverbs.
      ToAdverb = true;
      #> Prefers `to back out` (verb) over `to backout`.
      ToBackOut = true;
      #> Expands initialism `TBH`.
      ToBeHonest = true;
      #> Hyphenates `to-do`.
      ToDoHyphen = true;
      #> Corrects `through great lengths` → `to great lengths`.
      ToGreatLengths = true;
      #> Corrects `to lose too loose` confusions.
      ToLoseTooLoose = true;
      #> Suggests `tomorrow's` as attributive modifier.
      TomorrowPossessiveModifier = true;
      #> Corrects `tongue in cheek` idiom.
      TongueInCheek = true;
      #> Corrects `too` → `to`.
      TooTo = true;
      #> Corrects `in some degree` → `to some degree`.
      ToSomeDegree = true;
      #> Flags `tote`/`tout` confusion.
      ToteTout = true;
      #> Corrects `to the manor born` → `to the manner born`.
      ToTheMannerBorn = true;
      #> Fixes `to to` → remove or `to do`.
      ToTo = true;
      #> Corrects `to` → `too` in common idioms.
      ToTooIdioms = true;
      #> Handles `to`/`too`/`two` homophones.
      ToTwoToo = true;
      #> Suggests `tourist`/`tourism`/`touristy` over `touristic`.
      Touristic = true;
      #> Removes redundant `to` before `towards`.
      Towards = true;
      #> Fixes `to worried about`.
      ToWorryAbout = true;
      #> Fixes spacing inside `tradeoff`.
      Tradeoff = true;
      #> Fixes spaced one character too early/late.
      TransposedSpace = true;
      #> Corrects `trail and error` → `trial and error`.
      TrialAndError = true;
      #> Normalises `true to <possessive>` phrasing.
      TrueToWord = true;
      #> Flags redundant `truth to the fact`.
      TruthToTheFact = true;
      #> Corrects `try one's hands at` → `hand`.
      TryOnesHandAt = true;
      #> Corrects `try out one's luck` → `try one's luck`.
      TryOnesLuck = true;
      #> Corrects `tuff` → `tough` in common phrases.
      TuffEnough = true;
      #> Tumblr product names must be proper nouns.
      TumblrNames = true;
      #> Fixes `turn if off` → `turn it off`.
      TurnItOff = true;
      #> Requires closed quotes.
      UnclosedQuotes = true;
      #> Fixes spacing inside `underclock`.
      Underclock = true;
      #> Corrects `underneath of`.
      UnderneathOf = true;
      #> Organisation names must be proper nouns.
      UnitedOrganizations = true;
      #> Corrects `unless if`.
      Unless = true;
      #> Flags deprecated place names.
      UpdatePlaceNames = true;
      #> Fixes spacing inside `upset`.
      Upset = true;
      #> Fixes spacing inside `upward`.
      Upward = true;
      #> Replaces `...` with `…`.
      UseEllipsisCharacter = true;
      #> Prefers title case in headings.
      UseTitleCase = true;
      #> Corrects `use to` → `used to` (accustomed).
      UseToUsedTo = true;
      #> US university names must be proper nouns.
      USUniversities = true;
      #> Corrects adverb after article where adjective fits.
      VerbToAdjective = true;
      #> Corrects `verse` (as verb) to standard.
      VerseAsVerb = true;
      #> Flags `very known` → `well-known`.
      VeryKnown = true;
      #> Corrects `very less` (non-native idiom).
      VeryLess = true;
      #> Flags redundant `very much so`.
      VeryMuchSo = true;
      #> Flags `very unique`/`pretty unique`.
      VeryUnique = true;
      #> No hyphen in `vice versa`.
      ViceVersa = true;
      #> Corrects `vicious/virtuous circle` variants.
      ViciousCircle = true;
      #> Distinguishes `vicious/virtuous circle` from `cycle`.
      #! default: false
      ViciousCircleOrCycle = false;
      #> Distinguishes `vicious/virtuous cycle` variants.
      #! default: false
      ViciousCycle = false;
      #> Corrects `waste` → `waist` (body part).
      WaistWaste = true;
      #> Corrects `want be` → `won't be`/`want to be`.
      WantBe = true;
      #> Corrects `was aloud` → `was allowed`.
      WasAloud = true;
      #> Rewrites `was comprised of`.
      WasComprisedOf = true;
      #> Fixes `wavefunction` → `wave function`.
      WaveFunction = true;
      #> Replaces `way to` → `way too` + adjective.
      WayTooAdjective = true;
      #> Corrects `scrapping the web` → `scraping`.
      WebScraping = true;
      #> Hyphenates `well-being`.
      WellBeing = true;
      #> Replaces `good-educated` → `well-educated`.
      WellEducated = true;
      #> Prefers `well-kept` over `highly-kept`.
      WellKept = true;
      #> Corrects `went ahead and <present tense>`.
      WentAheadAndAgreement = true;
      #> Distinguishes `were` from `where`.
      WereWhere = true;
      #> Corrects `where as` → `whereas`.
      Whereas = true;
      #> Fixes spacing inside `whereupon`.
      Whereupon = true;
      #> Ensures `whet your appetite`.
      WhetYourAppetite = true;
      #> Collapses `whole entire` → `whole`/`entire`.
      WholeEntire = true;
      #> Detects `whom` used as subject.
      WhomSubjectOfVerb = true;
      #> Corrects `wide accepted` → `widely accepted`.
      WidelyAccepted = true;
      #> Fixes spacing inside `widespread`.
      Widespread = true;
      #> Corrects `will contain` (base form required).
      WillContain = true;
      #> Corrects `will gonna`/`will going to` → `will`.
      WillGonna = true;
      #> Flags wrong verb forms after `will`/`shall`.
      WillNonLemma = true;
      #> Corrects `win price`/`prise` → `win prize`.
      WinPrize = true;
      #> Corrects `wish can` → `wish could`.
      WishCould = true;
      #> Corrects `with open arms` variants.
      WithOpenArms = true;
      #> Fixes spacing inside `without`.
      Without = true;
      #> Collapses `without out` → `without`.
      WithoutOut = true;
      #> Fixes `wok` → `work` typo.
      WokVerbTypo = true;
      #> Ensures `WordPress.com` capitalisation.
      WordPressDotcom = true;
      #> Fixes spacing inside `worldwide`.
      Worldwide = true;
      #> Distinguishes `worse` from `worst`.
      WorseOrWorst = true;
      #> Hyphenates `worst-case scenario`.
      WorstCaseScenario = true;
      #> Corrects `worth to <verb>` → `worth <verb>ing`.
      WorthToDo = true;
      #> Fixes spacing inside `worthwhile`.
      Whilewhile = true;
      #> Corrects `would/could have never`.
      WouldNeverHave = true;
      #> Corrects `wreck havoc` → `wreak havoc`.
      WreakHavoc = true;
      #> Corrects semicolons, acute accents, backticks for apostrophes.
      WrongApostrophe = true;
      #> Flags unknown negative words.
      WrongNegative = true;
      #> Corrects `by wrote` → `by rote`.
      WroteToRote = true;
      #> Fixes `rod iron`/`rot iron` → `wrought iron`.
      WroughtIron = true;
      #> Corrects `yea` → `yeah`.
      YeaToYeah = true;
      #> Corrects `yeh` → `yeah`.
      YehToYeah = true;
      #> Corrects `your out` → `you're out`.
      YourOutClauseAgreement = true;
      #> Corrects `your <adjective>` → `you're <adjective>`.
      YourPredicateAdjective = true;
      #> Fixes spacing inside `yourself`.
      Yourself = true;
    };
  };
in {inherit enable extensions options settings;}
