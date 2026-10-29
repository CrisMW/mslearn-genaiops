---
lab:
    title: 'Plan and prepare a GenAIOps solution'
    description: 'Deploy Microsoft Foundry resources and configure your development environment for building generative AI applications.'
    level: 200
    duration: 20 minutes
---

# Set up your Microsoft Foundry project

This exercise takes approximately **20 minutes**.

> **Note**: This lab assumes a pre-configured lab environment with Visual Studio Code, Azure CLI, and Python already installed.

## Introduction

In this exercise, you'll set up the foundational infrastructure needed for developing and deploying generative AI applications. You'll use the Azure CLI to provision a Microsoft Foundry hub and project, along with supporting resources like Application Insights for monitoring.

You'll authenticate with Azure, provision all required cloud resources, and install the necessary Python dependencies. This will prepare your environment for building AI agents and applications in subsequent labs.

## Set up the environment

All steps in this lab will be performed using Visual Studio Code and its integrated terminal.

### Create repository from template

To complete the tasks in this exercise, you'll create your own repository from the template to practice realistic workflows.

1. In a web browser, navigate to `https://github.com/MicrosoftLearning/mslearn-genaiops`.
1. Select **Use this template** > **Create a new repository**.
1. Enter a name for your repository (e.g., `mslearn-genaiops`).
1. Set the repository to **Public** or **Private** based on your preference.
1. Select **Create repository**.

### Clone the repository in Visual Studio Code

1. In Visual Studio Code, open the Command Palette by pressing **Ctrl+Shift+P**.
1. Type **Git: Clone** and select it.
1. Enter your repository URL: `https://github.com/[your-username]/mslearn-genaiops.git`
1. Select a location on your local machine to clone the repository.
1. When prompted, select **Open** to open the cloned repository in VS Code.

### Deploy Microsoft Foundry resources

You'll use the Azure CLI to deploy all required Azure resources using the infrastructure files provided in this repository.

> **Note**: This repository includes pre-configured infrastructure files (the `infra/` folder) that define all the Azure resources needed for this lab.

1. In Visual Studio Code, open a new terminal by selecting **Terminal** > **New Terminal** from the menu.
1. Authenticate with Azure CLI:

    ```bash
    az login
    ```

    Sign in with your Azure credentials when prompted. This authentication is needed for the Python SDK and other Azure operations in subsequent labs.

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

    The command deploys the Bicep templates from the `infra/` folder.

    **Resources created:**
    - **Resource Group** - Existing `rg-swo-ds-sandbox-lab`, not created or modified
    - **Foundry (AI Services)** - Existing account `aif-swecen-bsmj-claude`, reused as is
    - **Foundry Project** - Existing project `proj-default`, reused as is
    - **Log Analytics Workspace** - Collects logs and telemetry data
    - **Application Insights** - Monitors agent performance and usage

    > **Note**: The core components you'll use are the Foundry hub and Project. The default template currently suggests GPT-5.1, but model availability varies by region and over time.

1. Create a `.env` file with the environment variables:

    ```bash
    az deployment group show --resource-group rg-swo-ds-sandbox-lab --name trail-guide-infra --query properties.outputs -o json \
      | jq -r 'to_entries[] | "\(.key | ascii_upcase)=\"\(.value.value)\""' > .env
    echo "AZURE_SUBSCRIPTION_ID=\"$(az account show --query id -o tsv)\"" >> .env
    ```
    


    This creates a `.env` file in your project root with all the provisioned resource information:
    - Resource names and IDs
    - Endpoints for AI Services and Project
    - Azure subscription and location details

    You can use these variables in your code and notebooks to connect to your Foundry resources.

### Install Python dependencies

Install the required Python packages to work with Microsoft Foundry in your applications.

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

### Configure agent settings

Add the required agent configuration to your environment variables.

1. In VS Code, open the `.env` file in the repository root.
1. Add the following lines at the end of the file:

    ```
    AGENT_NAME="trail-guide"
    MODEL_NAME="<model_name>"
    ```

    > **Note**: Set `MODEL_NAME` to the deployed chat model you want to use in your environment. For example, if you kept the template default and it is available in your region, you can use `gpt-5.1`.

1. Save the file.

### Create your first agent

Deploy the initial version of the Trail Guide Agent to Microsoft Foundry.

1. In the VS Code terminal, navigate to the agent directory:

    ```bash
    cd src/agents/trail_guide_agent
    ```

1. Run the agent creation script:

    ```bash
    python trail_guide_agent.py
    ```

    You should see output confirming the agent was created:

    ```
    Agent created (id: agent_xxx, name: trail-guide, version: 1)
    ```

### Test your agent

Interact with your deployed agent from the terminal to verify it's working correctly.

1. In the VS Code terminal, navigate back to the repository root:

    ```bash
    cd ../../..
    ```

1. Run the interactive test script:

    ```bash
    python src/tests/interact_with_agent.py
    ```

1. When prompted, ask the agent a question about hiking, for example:

    ```
    I want to go hiking this weekend near Seattle. Any suggestions?
    ```

1. The agent will respond with trail recommendations. Continue the conversation or type `exit` to quit.

    ```
    Agent: I'd recommend checking out Rattlesnake Ledge Trail...
    ```

    ```
    exit
    ```

## Verify your deployment

After deployment completes, verify that all resources are accessible and your agent is deployed.

1. In a web browser, open the [Microsoft Foundry portal](https://ai.azure.com) at `https://ai.azure.com` and sign in using your Azure credentials.
1. In the home page, select your newly created project from the list.
1. In the left navigation, select **Agents** to see your deployed Trail Guide Agent.
1. Verify you can see your agent (e.g., `trail-guide`) in the list.

## Where to find other labs

You can explore additional labs and exercises in the [Microsoft Foundry Learning Portal](https://ai.azure.com) or refer to the course's **lab section** for other available activities.

