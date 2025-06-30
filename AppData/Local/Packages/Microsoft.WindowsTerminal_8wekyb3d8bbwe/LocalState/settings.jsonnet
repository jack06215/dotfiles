{
  "$help": "https://aka.ms/terminal-documentation",
  "$schema": "https://aka.ms/terminal-profiles-schema",

  local profileList = [
    {
      guid: "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
      hidden: false,
      name: "PowerShell",
      source: "Windows.Terminal.PowershellCore",
    },
    {
      guid: "{bf2a0656-2c0e-586b-8e6b-6e5509a0c984}",
      hidden: false,
      name: "ubuntu_default2404",
      source: "Microsoft.WSL",
    },
    // {
    //   commandline: "%WINDIR%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -ExecutionPolicy ByPass -NoExit -Command \"& 'C:\\Users\\jack0\\anaconda3\\shell\\condabin\\conda-hook.ps1' ; conda activate 'C:\\Users\\jack0\\anaconda3' \"",
    //   guid: "{eed49005-877d-5de2-94d5-5ce5e370f8c3}",
    //   icon: "C:\\Users\\jack0\\anaconda3\\Menu\\anaconda_powershell_prompt.ico",
    //   name: "Anaconda PowerShell Prompt (anaconda3)",
    //   startingDirectory: "C:\\Users\\jack0",
    // },
    // {
    //   commandline: "%WINDIR%\\System32\\cmd.exe \"/K\" C:\\Users\\jack0\\anaconda3\\Scripts\\activate.bat C:\\Users\\jack0\\anaconda3",
    //   guid: "{e78b37b4-0017-568b-9279-1abde5e14cde}",
    //   icon: "C:\\Users\\jack0\\anaconda3\\Menu\\anaconda_prompt.ico",
    //   name: "Anaconda Prompt (anaconda3)",
    //   startingDirectory: "C:\\Users\\jack0",
    // },
  ],

  actions: [
    {
      command: "find",
      id: "User.find",
    },
    {
      command: {
        action: "splitPane",
        split: "auto",
        splitMode: "duplicate",
      },
      id: "User.splitPane.A6751878",
    },
    {
      command: "paste",
      id: "User.paste",
    },
    {
      command: {
        action: "copy",
        singleLine: false,
      },
      id: "User.copy.644BA8F2",
    },
  ],

  copyFormatting: "none",
  copyOnSelect: false,
  defaultProfile: "{574e775e-4f2a-5b96-ac1e-a2962a402336}",

  keybindings: [
    { id: "User.find", keys: "ctrl+shift+f" },
    { id: "User.paste", keys: "ctrl+v" },
    { id: "User.copy.644BA8F2", keys: "ctrl+c" },
    { id: "User.splitPane.A6751878", keys: "alt+shift+d" },
  ],

  firstWindowPreference: "defaultProfile",
  launchMode: "maximized",

  profiles: {
    defaults: {
      colorScheme: "xcad",
      cursorShape: "filledBox",
      font: {
        face: "PlemolJP Console NF",
        weight: "medium",
        size: 12,
      },
      historySize: 12000,
      intenseTextStyle: "bright",
      opacity: 65,
      padding: "8",
      scrollbarState: "visible",
      useAcrylic: false,
    },
    list: profileList,
  },

  schemes: [
    {
      name: "xcad",
      background: "#1A1A1A",
      black: "#121212",
      red: "#FF4C4C",
      green: "#3AFF7F",
      yellow: "#FFD93D",
      blue: "#2B4FFF",
      purple: "#4F6FFF",
      cyan: "#28B9FF",
      white: "#F1F1F1",

      brightBlack: "#666666",
      brightRed: "#FF7373",
      brightGreen: "#7DFFA2",
      brightYellow: "#FFE48D",
      brightBlue: "#5C78FF",
      brightPurple: "#7F9FFF",
      brightCyan: "#5AC8FF",
      brightWhite: "#FFFFFF",

      cursorColor: "#FFFFFF",
      selectionBackground: "#FFFFFF",
      foreground: "#F1F1F1",
    },
  ],

  showTabsInTitlebar: true,
  tabSwitcherMode: "inOrder",
  useAcrylicInTabRow: true,
}
