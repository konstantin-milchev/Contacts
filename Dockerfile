# Stage 1: Base
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

# Stage 2: Build
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# Copy the .csproj files and restore any dependencies (including Contacts and Contacts.Data)
COPY ["Contacts/Contacts.csproj", "Contacts/"]
COPY ["Contacts.Data/Contacts.Data.csproj", "Contacts.Data/"]
RUN dotnet restore "Contacts/Contacts.csproj"

# Copy the rest of the application and build it
COPY . .
WORKDIR "/src/Contacts"
RUN dotnet build "Contacts.csproj" -c Release -o /app/build

# Stage 3: Publish
FROM build AS publish
WORKDIR /src/Contacts
RUN dotnet publish "Contacts.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Stage 4: Final
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Contacts.dll"]