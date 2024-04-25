Function Print-HelloWorld
{
    $PrintHelloWorldSource = Get-Content -Raw -Path .\Source.cs
    Add-Type -TypeDefinition $PrintHelloWorldSource -Language CSharp
    [PsWinApiStuff.HelloWorld]::PrintHelloWorld()
}

Print-HelloWorld
