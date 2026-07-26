param (
    [string]$commitMessage #parametro para receber a mensagem de commit do usuário
)

git add *
git commit -m $commitMessage
git push RYS master