# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app
COPY . .
ENTRYPOINT ["dotnet", "Scheduling-Integration-Solution.dll"]
EXPOSE 80
EXPOSE 443