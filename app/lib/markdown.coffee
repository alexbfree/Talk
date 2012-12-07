module.exports= 
  runEditor: (className,name)->
    setTimeout ->
      c =  new Markdown.Converter(); 
      e = new Markdown.Editor(c,className);
      e.run()
      $(".togglePreview").click (e) ->  
        e.preventDefault() 
        $("#wmd-preview#{className}").toggle()
        el = $(".togglePreview")
        if el.html() == "Show Preview" then el.html("Hide Preview") else el.html("Show Preview")
    ,20

  convert:(content)->
    (new Markdown.Converter()).makeHtml(content || "")
    