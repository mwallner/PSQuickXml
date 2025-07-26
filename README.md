# PSQuickXml

**PSQuickXml** is a PowerShell script/module for efficiently reading and processing XML files using a forward-only `XmlReader`. It is designed for speed and low memory usage, making it suitable for large XML files. You provide a script block that is called for each node, receiving a hashtable with node information.

## Features

- Fast, low-memory XML parsing using .NET's `XmlReader`
- User-supplied script block (`-OnNode`) called for each node
- Optional filtering of nodes by name (`-WantedNodes`)
- When filtering, provides the full subtree of matched nodes as `[xml]` objects in the hashtable
- Handles both element and text nodes (unless filtering)

## Usage

```powershell
PS> .\Read-QuickXml.ps1 -Path 'input.xml' -OnNode { param($node) $node }
```

### Parameters

- **Path**: Path to the XML file to read (required)
- **OnNode**: Script block to call for each processed node. Receives a hashtable with node info (required)
- **WantedNodes**: Optional array of node names to filter which nodes are processed. If specified, only these nodes are processed, and the hashtable includes an `xml` property with the children of the matched node as `[xml]` objects.

## Output

Each call to your `-OnNode` script block receives a hashtable with keys such as:

- `Name`: Node name
- `Depth`: Depth in the XML tree
- `IsEmpty`: Whether the element is empty
- `NodeType`: 'Element' or 'Text'
- `Attributes`: Hashtable of attributes (for elements)
- `Value`: Text value (for text nodes)
- `xml`: Array of `[xml]` child nodes (only when `-WantedNodes` is used and node matches)

## Testing

Pester tests are provided in the `tests/` directory. To run tests:

```powershell
Invoke-Pester -Path ./tests
```

## License

MIT - see [LICENSE](LICENSE.txt)
