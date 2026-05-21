state("LEGOIndy")
{
}

startup
{
	settings.Add("roomSplitsComp", true, "Show comp to final split total for comparison (for room splitter ILs)");
    settings.Add("currentSplitComp", false, "Show comp of current split in comparison");
}



init
{

    // Define the 4 sequential mailboxes based on your pointer offset
    vars.Mailbox1 = new DeepPointer(0x6ADEE4, 0xBD3CA); // Total Time
    vars.Mailbox2 = new DeepPointer(0x6ADEE4, 0xBD3CE); // Segment Time
    vars.Mailbox3 = new DeepPointer(0x6ADEE4, 0xBD3D2); // Total Time extra comparison. Will either be current split's comparison time or will be the last split's final time for the current comparison.
    vars.Mailbox4 = new DeepPointer(0x6ADEE4, 0xBD3D6); // Current comparison's time for this split
}

update
{
    // 1. Reset values if timer isn't running
    if (timer.CurrentPhase == TimerPhase.NotRunning)
    {
        IntPtr a1, a2, a3, a4;
        if (vars.Mailbox1.DerefOffsets(game, out a1)) game.WriteValue<float>(a1, 0f);
        if (vars.Mailbox2.DerefOffsets(game, out a2)) game.WriteValue<float>(a2, 0f);
        if (vars.Mailbox3.DerefOffsets(game, out a3)) game.WriteValue<float>(a3, 0f);
        if (vars.Mailbox4.DerefOffsets(game, out a4)) game.WriteValue<float>(a4, 0f);
        return;
    }

    var currentTime = timer.CurrentTime.GameTime;
    if (!currentTime.HasValue) return;

    float totalSeconds = (float)currentTime.Value.TotalSeconds;
    float segmentSeconds = totalSeconds;

    int index = timer.CurrentSplitIndex;

    // Prevent out-of-bounds errors when the run is finished
    if (index >= timer.Run.Count) 
    {
        index = timer.Run.Count - 1;
    }

    // Calculate current run's segment time (Mailbox 2)
    if (index > 0)
    {
        var prevSplitTime = timer.Run[index - 1].SplitTime.GameTime;
        if (prevSplitTime.HasValue)
        {
            segmentSeconds = totalSeconds - (float)prevSplitTime.Value.TotalSeconds;
        }
    }

    string comp = timer.CurrentComparison;

    // Calculate current split's Comparison Split Time (For Mailbox 3)
    float currentCompSplitSeconds = 0f;
    var compSplitTime = timer.Run[index].Comparisons[comp].GameTime;
    if (compSplitTime.HasValue) 
    {
        currentCompSplitSeconds = (float)compSplitTime.Value.TotalSeconds;
    }

    // Calculate current split's Comparison Segment Time (For Mailbox 4)
    float currentCompSegmentSeconds = currentCompSplitSeconds; // Defaults to split time if it's the first split
    if (index > 0) 
    {
        var prevCompSplitTime = timer.Run[index - 1].Comparisons[comp].GameTime;
        if (compSplitTime.HasValue && prevCompSplitTime.HasValue) 
        {
            currentCompSegmentSeconds = (float)(compSplitTime.Value.TotalSeconds - prevCompSplitTime.Value.TotalSeconds);
        }
    }

    // Calculate the final split's Comparison Split Time (For Mailbox 3 Toggle)
    float finalCompSplitSeconds = 0f;
    var finalCompTime = timer.Run[timer.Run.Count - 1].Comparisons[comp].GameTime;
    if (finalCompTime.HasValue) 
    {
        finalCompSplitSeconds = (float)finalCompTime.Value.TotalSeconds;
    }

    // Determine what goes into Mailbox 3 based on your settings
    float mailbox3Value = currentCompSplitSeconds;
    if (settings["roomSplitsComp"]) 
    {
        mailbox3Value = finalCompSplitSeconds;
    }

    // 3. Dereference and Write to all 4 mailboxes
    IntPtr addr1, addr2, addr3, addr4;
    if (vars.Mailbox1.DerefOffsets(game, out addr1)) game.WriteValue<float>(addr1, totalSeconds);
    if (vars.Mailbox2.DerefOffsets(game, out addr2)) game.WriteValue<float>(addr2, segmentSeconds);
    if (vars.Mailbox3.DerefOffsets(game, out addr3)) game.WriteValue<float>(addr3, mailbox3Value);
    if (vars.Mailbox4.DerefOffsets(game, out addr4)) game.WriteValue<float>(addr4, currentCompSegmentSeconds);
}