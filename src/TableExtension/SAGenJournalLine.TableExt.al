tableextension 55102 SAGenJournalLine extends "Gen. Journal Line"
{
    fields
    {
        field(55100; SAChaseCheckApplied; Boolean)
        {
            AllowInCustomizations = AsReadWrite;
            DataClassification = CustomerContent;
            Caption = 'Chase Check Applied (Yes/No)';
        }
    }
}