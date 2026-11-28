reduce (.resource_changes[]? | select(.mode == "managed") | .change.actions) as $actions
  ({add: 0, change: 0, delete: 0};
    .add += (if $actions | index("create") then 1 else 0 end) |
    .change += (if $actions | index("update") then 1 else 0 end) |
    .delete += (if $actions | index("delete") then 1 else 0 end))
