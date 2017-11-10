if _G.ngx and _G.ngx.thread then
  return require 'rover/parallel/ngx'
else
  return require 'rover/parallel/default'
end
