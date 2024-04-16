Function Print-HelloWorld
{
     $PrintHelloWorldSource = @"
using System;
namespace HelloWorld
{
    public static class HelloWorldClass
    {
        public static void PrintHelloWorld() 
        {
            Console.WriteLine("Hello World!");
        }
    }
}
"@
    Add-Type -TypeDefinition $PrintHelloWorldSource -Language CSharp
    [HelloWorld.HelloWorldClass]::PrintHelloWorld()
}

Print-HelloWorld
