from rich.align import Align
from rich.console import Console
from rich.text import Text

BANNER = """\
 █████╗  ██████╗ ███████╗███╗   ██╗████████╗███████╗██████╗ ███████╗ ██████╗
██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔════╝
███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║   ███████╗██████╔╝█████╗  ██║     
██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║   ╚════██║██╔═══╝ ██╔══╝  ██║     
██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║   ███████║██║     ███████╗╚██████╗
╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝     ╚══════╝ ╚═════╝
"""

TAGLINE = "AgentSpec - AI Agent Configuration Toolkit"

console = Console()


def show_banner() -> None:
    banner_lines = BANNER.strip().split("\n")
    colors = ["bright_blue", "blue", "cyan", "bright_cyan", "white", "bright_white"]

    styled = Text()
    for i, line in enumerate(banner_lines):
        color = colors[i % len(colors)]
        styled.append(line + "\n", style=color)

    console.print(Align.center(styled))
    console.print(Align.center(Text(TAGLINE, style="italic bright_yellow")))
    console.print()
