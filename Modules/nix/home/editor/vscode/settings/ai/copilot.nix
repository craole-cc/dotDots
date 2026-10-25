{
  context,
  mkEnable,
  requires,
  ...
}: let
  mod = "copilot";
  condition = requires [mod "github"];
  enable = condition;
  options.${mod}.enable = mkEnable {inherit context condition;};

  extensions = [
    "github.copilot"
    "github.copilot-chat"
  ];

  settings = {
    github.copilot = {
      # Object-valued setting: keep as a real attrset, do not flatten
      enable = {
        "*" = true;
        plaintext = false;
        markdown = false;
        scminput = false;
      };
      selectedCompletionModel = "";

      editor.enableCodeActions = true;
      renameSuggestions.triggerAutomatically = true;
      completions.chat.enabled = false;

      nextEditSuggestions = {
        allowWhitespaceOnlyChanges = true;
        eagerness = "auto";
        enabled = true;
        extendedRange = true;
        fixes = true;
        preferredModel = "none";
      };

      chat = {
        additionalReadAccessPaths = [];

        agent = {
          autoFix = false;
          backgroundTodoAgent.enabled = false;
          currentEditorContext.enabled = true;
          largeToolResultsToDisk = {
            enabled = true;
            thresholdBytes = 8192;
          };
          longToolCallCachePreservation = {
            enabled = false;
            maxProbes = 1;
          };
          # modelDetails.enabled = true; #! Deprecated
          omitFileAttachmentContents = false;
          temperature = 0;
        };

        agentDebugLog.fileLogging = {
          enabled = false;
          flushIntervalMs = 4000;
          maxRetainedSessionLogs = 50;
          maxSessionLogSizeMB = 100;
        };

        agentHistorySummarizationMode = "";
        alternateGeminiModelFPrompt.enabled = false;
        alternateGptPrompt.enabled = false;

        anthropic = {
          contextEditing.mode = "off";
          promptCaching = {
            extendedTtl = false;
            extendedTtlMessages = false;
          };
          useMessagesApi = true;
          tools.websearch = {
            allowedDomains = [];
            blockedDomains = [];
            enabled = false;
            maxUses = 5;
            userLocation = null;
          };
        };

        askAgent = {
          additionalTools = [];
          model = "";
        };

        # backgroundAgent.enabled = true; #! Deprecated
        chatCompletionsTokenParameter = "max_tokens";
        claudeDefaultReasoningEffort = "";
        claudeOpus5Prompt.enabled = false;
        claudeSonnet5Prompt.enabled = false;

        cli = {
          #   aiGenerateBranchNames.enabled = true; #! Deprecated
          #   autoCommit.enabled = true; #! Deprecated
          #   autoModel.enabled = true; #! Deprecated
          #   branchSupport.enabled = false; #! Deprecated
          #   forkSessions.enabled = true; #! Deprecated
          #   isolationOption.enabled = true; #! Deprecated
          #   lazyLoadSessionItem.enabled = true; #! Deprecated
          #   mcp.enabled = true; #! Deprecated
          #   planCommand.enabled = true; #! Deprecated
          #   planExitMode.enabled = true; #! Deprecated
          #   remote.enabled = true; #! Deprecated
          #   sandbox.enabled = "off"; #! Deprecated
          #   sessionController.enabled = false; #! Deprecated
          #   sessionControllerForSessionsApp.enabled = false; #! Deprecated
          terminalLinks.enabled = true;
        };

        cloudAgent.enabled = true;

        codeGeneration = {
          # instructions = []; #! Deprecated
          useInstructionFiles = true;
        };

        codesearch = {
          enabled = false;
          agent.enabled = true;
        };

        commitMessageGeneration.instructions = [];
        completionsFetcher = "electron-fetch"; #? ["electron-fetch" | "node-fetch"]
        copilotDebugCommand.enabled = true;
        customInstructionsInSystemMessage = true;

        debug = {
          promptOverrideFile = null;
          promptOverrideString = null;
          requestLogger.maxEntries = 100;
        };
        debugTerminalCommandPatterns = [];

        editRecording.enabled = false;
        edits = {
          batchReplaceStringDescriptions = false;
          gemini3MultiReplaceString = false;
        };
        enableUserPreferences = false;

        executionSubagent = {
          enabled = false;
          model = "gemini-3-flash";
          toolCallLimit = 10;
          turnWisePrompting = false;
          useAgenticProxy = false;
        };

        exploreAgent = {
          enabled = true;
          model = "";
        };

        feedback.onChange = false;
        gemini35FlashReducedToolUsePrompt.enabled = true;
        gemini3GetChangedFilesTool.enabled = false;
        geminiFlashPromptAdditions.enabled = true;
        getChangedFilesTool.enabled = false;

        githubMcpServer = {
          channel = "stable";
          enabled = false;
          lockdown = false;
          readonly = false;
          toolsets = ["default"];
        };

        gpt55GetChangedFilesTool.enabled = true;
        gpt55ReadFileTool.enabled = true;
        gpt56Verbosity.enabled = true;
        gpt5AlternativePatch = false;

        imageUpload.enabled = true;
        implementAgent.model = "";
        inlineChat.enableThinking = false;

        inlineEdits = {
          chatSessionContextProvider.enabled = false;
          diagnosticsContextProvider.enabled = false;
          nextCursorPrediction.currentFileMaxTokens = 3000;
          renameSymbolSuggestions = true;
          triggerOnEditorChangeAfterSeconds = 10;
          xtabProvider.modelConfiguration = null;
        };

        installExtensionSkill.enabled = false;

        instantApply = {
          shortContextLimit = 8000;
          shortContextModelName = "gpt-4o-instant-apply-full-ft-v66-short";
        };

        languageContext = {
          fix.typescript.enabled = false;
          inline.typescript.enabled = false;
          typescript = {
            cacheTimeout = 500;
            enabled = true;
            includeDocumentation = false;
            items = "double";
          };
          typescript7.enabled = false;
        };

        localeOverride = "auto";
        localIndex.enabled = true;
        localWorkspaceRecording.enabled = false;
        modelCapabilityOverrides = {};
        nesFetcher = "electron-fetch"; #? ["electron-fetch" | "node-fetch"]

        newWorkspace.useContext7 = false;
        newWorkspaceCreation.enabled = true;

        notebook = {
          alternativeFormat = "xml";
          alternativeNESFormat.enabled = false;
          enhancedNextEditSuggestions.enabled = false;
          followCellExecution.enabled = false;
          summaryExperimentEnabled = false;
          variableFilteringEnabled = false;
        };

        omitBaseAgentInstructions = false;
        organizationCustomAgents.enabled = true;
        organizationInstructions.enabled = true;

        otel = {
          captureContent = false;
          captureIdentity = null;
          dbSpanExporter.enabled = false;
          enabled = false;
          exporterType = "otlp-http";
          headers = {};
          maxAttributeSizeChars = 0;
          otlpEndpoint = "http://localhost:4318";
          outfile = "";
          protocol = "";
          resourceAttributes = {};
          serviceName = "";
        };

        planAgent.additionalTools = [];

        projectLabels = {
          chat = false;
          expanded = false;
          inline = false;
        };

        promptFileContextProvider.enabled = true;
        pullRequestDescriptionGeneration.instructions = [];
        rateLimitAutoSwitchToAuto = false;
        reasoningEffortOverride = null;

        responsesApi = {
          promptCacheBreakpoint.enabled = false;
          promptCacheKey.enabled = false;
        };
        responsesApiContextManagement.enabled = false;

        review.intent = false;
        reviewAgent.enabled = true;
        reviewSelection = {
          enabled = true;
          instructions = [];
        };

        scopeSelection = false;

        searchSubagent = {
          enabled = false;
          model = "";
          subagentSemanticSearchEnabled = true;
          thoroughnessEnabled = false;
          toolCallLimit = 4;
          useAgenticProxy = false;
        };

        setupTests.enabled = true;
        skillTool.enabled = false;
        summarizeAgentConversationHistory.enabled = true;
        summarizeAgentConversationHistoryThreshold = 0;
        switchAgent.enabled = false;
        terminalChatLocation = "chatView";
        # testGeneration.instructions = []; #! Deprecated

        tools = {
          defaultToolsGrouped = false;
          grepSearch = {
            defaultMaxResults = 100;
            maxResultsCap = 200;
            outputFormat = "grep";
          };
          viewImage.enabled = true;
        };

        updated53CodexPrompt.enabled = true;
        useProjectTemplates = true;
        useResponsesApiTruncation = false;
        virtualTools.threshold = 128;

        workspace = {
          codeSearchExternalIngest.enabled = true;
          enableCodeSearch = true;
          maxLocalIndexSize = 100000;
          preferredEmbeddingsModel = "";
        };
      };
    };

    chat = {
      experimental.stickyScroll.enabled = false;
      sessionSync = {
        enable = true;
        excludeRepositories = [];
      };
      tools.terminal.autoApprove = {
        awk = true;
        cksum = true;
        command = true;
        nix = true;
        printf = true;
        zig = true;
      };
      viewSessions.orientation = "stacked";
    };
  };
in {inherit enable options extensions settings;}
