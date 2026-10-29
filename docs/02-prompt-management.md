---
lab:
    title: 'Develop prompt and agent versions'
    description: 'Create and deploy multiple versions of AI agents using prompt engineering and version management in Microsoft Foundry.'
    level: 200
    duration: 30 minutes
---

# Develop prompt and agent versions

This exercise takes approximately **30 minutes**.

> **Note**: This lab assumes a pre-configured lab environment with Visual Studio Code, Azure CLI, and Python already installed.

## Introduction

In this exercise, you'll deploy multiple versions of a Trail Guide Agent to Microsoft Foundry, each with progressively enhanced capabilities. You'll use Python scripts to create agents with different system prompts, test their behavior in the portal, and run automated tests to compare their performance.

You'll modify a single Python script to deploy three agent versions (V1, V2, and V3), review each deployment in the Microsoft Foundry portal, and analyze how prompt evolution affects agent behavior. This will help you understand version management strategies and the relationship between programmatic deployment and portal-based agent management.

## Set up the environment

To complete the tasks in this exercise, you need:

- Visual Studio Code
- Azure subscription with Microsoft Foundry access
- Git and [GitHub](https://github.com) account
- Python 3.9 or later
- Azure CLI installed

All steps in this lab will be performed using Visual Studio Code and its integrated terminal.

### Create repository from template

You'll start by creating your own repository from the template to practice realistic workflows.

1. In a web browser, navigate to the template repository on [GitHub](https://github.com) at `https://github.com/MicrosoftLearning/mslearn-genaiops`.
1. Select **Use this template** > **Create a new repository**.
1. Enter a name for your repository (e.g., `mslearn-genaiops`).
1. Set the repository to **Public** or **Private** based on your preference.
1. Select **Create repository**.

### Clone the repository in Visual Studio Code

After creating your repository, clone it to your local machine.

1. In Visual Studio Code, open the Command Palette by pressing **Ctrl+Shift+P**.
1. Type **Git: Clone** and select it.
1. Enter your repository URL: `https://github.com/[your-username]/mslearn-genaiops.git`
1. Select a location on your local machine to clone the repository.
1. When prompted, select **Open** to open the cloned repository in VS Code.

### Deploy Microsoft Foundry resources

Now you'll use the Azure CLI to deploy all required Azure resources.

> **Note**: This lab uses infrastructure-as-code (IaC) deployment with Bicep because it follows GenAIOps best practices and makes the lab accessible as a standalone exercise. This approach ensures consistent, reproducible environments while teaching real-world deployment patterns.

1. In Visual Studio Code, open a terminal by selecting **Terminal** > **New Terminal** from the menu.

1. Authenticate with Azure CLI:

    ```bash
    az login
    ```

    Sign in with your Azure credentials when prompted.

    > ⚠️ **Important**
    > In some environments, the VS Code integrated terminal may crash or close during the interactive login flow.
    > If this happens, use device code authentication instead:
    > ```bash
    > az login --use-device-code
    > ```

1. Deploy into the existing resource group, reusing the existing Foundry account and project:

    ```bash
    export AZURE_ENV_NAME="trail-guide"
    export AZURE_LOCATION="swedencentral"
    export AZURE_AI_ACCOUNT_NAME="aif-swecen-bsmj-claude"
    export AZURE_AI_PROJECT_NAME="proj-default"
    export ASSIGN_LOCAL_USER_FOUNDRY_ROLE="false"
    export ENABLE_HOSTED_AGENTS="false"
    export AZURE_PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv)
    az deployment group create --resource-group rg-swo-ds-sandbox-lab --name trail-guide-infra --parameters infra/main.bicepparam
    ```

    > **Note**: If the deployment fails because the default model is unavailable in your region, update the `aiProjectDeploymentsJson` block in `infra/main.bicep` to a compatible model and rerun the deployment command.

    `AZURE_ENV_NAME` is used to tag and name the resources and `AZURE_LOCATION` sets the region (recommended: Sweden Central). Run `az account set --subscription <subscription-id>` first if you need a different subscription.

    The command deploys the `infra/` templates against existing resources:
    - **Resource Group** - Existing `rg-swo-ds-sandbox-lab`, not created or modified
    - **Foundry (AI Services)** - Existing account `aif-swecen-bsmj-claude`, reused as is
    - **Foundry Project** - Existing project `proj-default`, reused as is
    - **Log Analytics Workspace** - Collects logs and telemetry data
    - **Application Insights** - Monitors agent performance and usage

1. Create a `.env` file with the environment variables:

    ```bash
    az deployment group show --resource-group rg-swo-ds-sandbox-lab --name trail-guide-infra --query properties.outputs -o json \
      | jq -r 'to_entries[] | "\(.key | ascii_upcase)=\"\(.value.value)\""' > .env
    echo "AZURE_SUBSCRIPTION_ID=\"$(az account show --query id -o tsv)\"" >> .env
    ```


    This creates a `.env` file in your project root with all the provisioned resource information.

1. Add the agent configuration to your `.env` file:

    ```
    AGENT_NAME="trail-guide"
    MODEL_NAME="<model_name>"
    ```

    > **Note**: Set `MODEL_NAME` to the deployed model you want to use in your environment. For example, if you kept the template default and it is available in your region, you can use `gpt-5.1`.

### Install Python dependencies

With your Azure resources deployed, install the required Python packages to work with Microsoft Foundry.

1. In the VS Code terminal, create and activate a virtual environment:

    ```bash
    python -m venv .venv
    source .venv/bin/activate
    ```

1. Install the required dependencies:

    ```bash
    python -m pip install -r requirements.txt
    ```

    This installs all necessary dependencies including:
    - `azure-ai-projects` - SDK for working with Microsoft Foundry agents
    - `azure-identity` - Azure authentication
    - `python-dotenv` - Load environment variables
    - Other evaluation, testing, and development tools

## Deploy and test agent versions

You'll deploy three versions of the Trail Guide Agent, each with different system prompts that progressively enhance capabilities.

### Deploy trail guide agent V1

Start by deploying the first version of the trail guide agent.

1. In the VS Code terminal, navigate to the trail guide agent directory:

    ```bash
    cd src/agents/trail_guide_agent
    ```

1. Open the agent creation script (`trail_guide_agent.py`) and locate the line that reads the prompt file:
   
    ```python
    prompt_file = Path(__file__).parent / 'prompts' / 'v1_instructions.txt'
    with open(prompt_file, 'r') as f:
        instructions = f.read().strip()
    ```

    Verify it's configured to read from `v1_instructions.txt`.

1. Run the agent creation script:

    ```bash
    python trail_guide_agent.py
    ```

    You should see output confirming the agent was created:

    ```
    Agent created (id: agent_xxx, name: trail-guide, version: 1)
    ```

    Note the Agent ID for later use.

1. Commit your changes and tag the version:

    > ⚠️ **First-time Git setup required**
    >
    > Before committing, Git requires your identity to be configured. 
    > Run the following commands in the terminal, replacing the values with your GitHub username and email:
    > ```bash
    > git config --global user.name "Your GitHub Username"
    > git config --global user.email "your-email@example.com"
    > ```

    ```bash
    git add trail_guide_agent.py
    git commit -m "Deploy trail guide agent V1"
    git tag v1
    ```

### Test agent V1

Verify your agent is working by testing it in the Microsoft Foundry portal.

1. In a web browser, open the [Microsoft Foundry portal](https://ai.azure.com) at `https://ai.azure.com` and sign in using your Azure credentials.
1. Ensure you have the **New Foundry** toggle enabled.
1. In the top navigation bar, select **Build**
1. Navigate to **Agents** in the left navigation.
1. Select your **trail-guide** agent from the list.
1. Test the agent by asking questions like:
   - "What gear do I need for a day hike?"
   - "Recommend a trail near Seattle for beginners"

### Deploy trail guide agent V2

Next, deploy a second version with enhanced capabilities.

1. Open `trail_guide_agent.py` and update the prompt file path:
   
   Change:
   ```python
    prompt_file = Path(__file__).parent / 'prompts' / 'v1_instructions.txt'
   ```
   
   To:
   ```python
    prompt_file = Path(__file__).parent / 'prompts' / 'v2_instructions.txt'
   ```

1. Run the agent creation script:

     ```bash
     python trail_guide_agent.py
     ```

    You should see output confirming the agent was created:

    ```
    Agent created (id: agent_yyy, name: trail-guide, version: 2)
    ```

    Note the Agent ID for later use.

1. Commit your changes and tag the version:

    ```bash
    git add trail_guide_agent.py
    git commit -m "Deploy trail guide agent V2 with enhanced capabilities"
    git tag v2
    ```

### Deploy trail guide agent V3

Finally, deploy the third version with production-ready features.

1. Open `trail_guide_agent.py` and update the prompt file path:
   
   Change:
   ```python
    prompt_file = Path(__file__).parent / 'prompts' / 'v2_instructions.txt'
   ```
   
   To:
   ```python
    prompt_file = Path(__file__).parent / 'prompts' / 'v3_instructions.txt'
   ```

1. Run the agent creation script:

    ```bash
    python trail_guide_agent.py
    ```

    You should see output confirming the agent was created:

    ```
    Agent created (id: agent_zzz, name: trail-guide, version: 3)
    ```

    Note the Agent ID for later use.

1. Commit your changes and tag the version:

    ```bash
    git add trail_guide_agent.py
    git commit -m "Deploy trail guide agent V3 with production features"
    git tag v3
    ```

## Compare agent versions

Now that you have three agent versions deployed, compare their behavior and prompt evolution.

### Review version history

Examine your Git tags to see the version history.

1. View all version tags:

    ```bash
    git tag
    ```

    You should see:
    ```
    v1
    v2
    v3
    ```

1. View the commit history with tags:

    ```bash
    git log --oneline --decorate
    ```

    This shows each deployment milestone marked with its corresponding tag.

### Review prompt differences

Examine the prompt files to understand how each version evolved.

1. In VS Code, open the three prompt files in the `prompts/` directory:
   - `v1_instructions.txt` - Basic trail guide functionality
   - `v2_instructions.txt` - Enhanced with personalization
   - `v3_instructions.txt` - Production-ready with advanced capabilities

1. Notice the evolution:
   - **V1 → V2**: Added personalization and enhanced guidance
   - **V2 → V3**: Added structured framework and enterprise features

1. In the Microsoft Foundry portal, test each agent version with the same question to observe behavior differences.
   
   Try this question: *"I'm planning a weekend hiking trip near Seattle. What should I know?"*
   
   Observe how each version responds:
   - **V1**: Provides basic trail recommendations and general advice
   - **V2**: Adds personalized suggestions based on experience level and preferences
   - **V3**: Includes comprehensive guidance with safety considerations, weather factors, and detailed planning steps

## Clean up

The resource group and Foundry account are shared, so do not delete them. The agent and its versions you created cost nothing while idle; no further cleanup is required.

## Next steps

Continue your learning journey by exploring agent evaluation techniques.

In the next lab, you'll learn to evaluate these agent versions using manual testing processes to determine which performs better for different scenarios and customer segments.
