codeunit 87101 "WanaStart Import FR"
{
    trigger OnRun()
    var
        ImportLine: Record "wanaStart Import Line";
        StartDateTime: DateTime;
        DoneMsg: Label '%1 lines imported in %2.';
        DeleteLines: Label 'Do you want to delete %1 previous lines?';
    begin
        if not ImportLine.IsEmpty then
            if Confirm(DeleteLines, false, ImportLine.Count) then
                ImportLine.DeleteAll(false);
        StartDateTime := CurrentDateTime;
        Xmlport.Run(Xmlport::"WanaStart FEC M&A", false, true, ImportLine);
        Message(DoneMsg, ImportLine.Count, CurrentDateTime - StartDateTime);
    end;
}
