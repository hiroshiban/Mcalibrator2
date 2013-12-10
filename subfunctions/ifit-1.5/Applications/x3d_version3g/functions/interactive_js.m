function str=interactive_js(number)
n=0;
n=n+1; lines{n}='<![CDATA[\n';
n=n+1; lines{n}='    var timerhandle, timeron=0;\n';
n=n+1; lines{n}=['    var numberobj=' num2str(number) ';\n'];

n=n+1; lines{n}='    var myLabel=new Array(numberobj);\n';
for j=1:number
n=n+1; lines{n}=['    myLabel[' num2str(j-1) ']="object ' num2str(j) '";\n'];
end
n=n+1; lines{n}='\n';
n=n+1; lines{n}='    function clickalert(id)\n';
n=n+1; lines{n}='    {\n';
n=n+1; lines{n}='        hideall();\n';
n=n+1; lines{n}='        document.getElementById("mshape" + id).setAttribute("transparency", "0.0");\n';
n=n+1; lines{n}='        document.getElementById("comments").value=myLabel[id];\n';
n=n+1; lines{n}='        if(timeron>0) { clearTimeout(timerhandle);} else { timeron=1; }\n';
n=n+1; lines{n}='        timerhandle=setTimeout("timeron=0; showall();",1000);\n';
n=n+1; lines{n}='    }\n';
n=n+1; lines{n}='\n';
n=n+1; lines{n}='    function hideall()\n';
n=n+1; lines{n}='    {\n';
n=n+1; lines{n}='        for (i=0;i<numberobj;i++)\n';
n=n+1; lines{n}='        {\n';	
n=n+1; lines{n}='            document.getElementById("mshape" + i).setAttribute("transparency", "0.9");\n';
n=n+1; lines{n}='        }\n';
n=n+1; lines{n}='    }\n';
n=n+1; lines{n}='    function showall()\n';
n=n+1; lines{n}='    {\n';
n=n+1; lines{n}='        for (i=0;i<numberobj;i++)\n';
n=n+1; lines{n}='        {\n';	
n=n+1; lines{n}='            document.getElementById("mshape" + i).setAttribute("transparency", "0.0");\n';
n=n+1; lines{n}='        }\n';
n=n+1; lines{n}='    }\n';
n=n+1; lines{n}=']]>\n';
str=sprintf([lines{:}]);
