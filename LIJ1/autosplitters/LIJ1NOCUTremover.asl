//Splitting by Siedemnastek, load remover by Tfresh and Sied. Room splitting by Lazer
state("LEGOIndy")
{
    int status : 0x6D39F0; //unused
    int statust : 0x6927D8;
    int newgame : 0x5C43C4;
    int newgamet : 0x6CC7A8;
    int stream : 0x6CC944;
    int door: 0x572EF0; //Old value for transitions, ended up being used to stop the reset address from removing random frames all over the place
    int menu: 0x56F864; 
    bool transition: 0x6C1664; 
    bool Loading: 0x5C3D24;
    bool Loading2: 0x6CC7A8;
    bool Reset: 0x572DA8;
    int GizLoop: 0x6D27B4;
    int roomSplit: 0x6ADFCC;
	bool cutscene: 0x5BBC5F;
}

startup
{
    settings.Add("any", true, "Any%/Raiders of the Lost Ark");
    settings.Add("temple", false, "Temple of Doom");
    settings.Add("crusade", false, "Last Crusade");
    settings.Add("fp", false, "FP/AA/100%");
    settings.Add("room", false, "Room Splitter");
    settings.Add("roomStart", false, "Start timer on room change");
	settings.Add("cutsceneRemover", false, "Pause timer during cutscenes (for NOCUT segments)");
    settings.Add("giz", true, "Show Gizmo Loop value");
    refreshRate = 255;

    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");

    vars.skipRooms = new List<int> {11,15,26,35,46,57,79,90,95,98,106,114,126,140,150,159,173,181,192,203};
}

update 
{
    if (settings["giz"]) 
    {
        vars.Helper.Texts["gizloop"].Left = "Gizmo Loop: ";
        vars.Helper.Texts["gizloop"].Right = current.GizLoop + "";
    }
}

onStart 
{
    if (settings["giz"]) 
    {
        vars.Helper.Texts["gizloop"].Left = "Gizmo Loop: ";
        vars.Helper.Texts["gizloop"].Right = current.gizmovalue + "";
    } 
    else 
    {
        vars.Helper.Texts.Remove("gizloop");
    }
}

split
{
    if (current.statust > old.statust && !current.Loading) return true;
    else if (settings["any"] && current.stream == 67 && old.stream == 66) return true;  
    else if (settings["temple"] && current.stream == 126 && old.stream == 125) return true;
    else if (settings["crusade"] && current.stream == 192 && old.stream == 191) return true;
    else if (settings ["room"] && (current.roomSplit != old.roomSplit) && old.roomSplit != 0 && !vars.skipRooms.Contains(current.stream)) return true;
    else if (settings ["room"] && old.stream == 10 && current.stream == 11) return true;
}

start
{
    if (current.newgame > old.newgame && current.newgamet > old.newgamet) return true;
    if (settings["roomStart"] && current.door == 13) return true;
}

reset
{
    if (current.stream == 0 && old.stream == 1) return true;
}

isLoading
{
    return current.Loading || current.Loading2 || current.Reset && current.door == 10000 || current.transition && current.menu < 1 || (settings["cutsceneRemover"] && current.cutscene);
}

exit 
{
timer.IsGameTimePaused = false;
}