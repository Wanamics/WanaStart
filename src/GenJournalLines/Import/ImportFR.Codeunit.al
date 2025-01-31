codeunit 87101 "WanaStart Import FR"
{
    trigger OnRun()
    var
        ImportFRLine: Record "WanaStart Import FR Line";
        StartDateTime: DateTime;
        DoneMsg: Label '%1 lines imported in %2.';
        DeleteLines: Label 'Do you want to delete %1 previous lines?';
    begin
        if not ImportFRLine.IsEmpty then
            if not Confirm(DeleteLines, false, ImportFRLine.Count) then
                exit
            else
                ImportFRLine.DeleteAll();
        StartDateTime := CurrentDateTime;
        Xmlport.Run(Xmlport::"FEC M&A", false, true, ImportFRLine);
        Message(DoneMsg, ImportFRLine.Count, CurrentDateTime - StartDateTime);
    end;
}
